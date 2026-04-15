#
# Created by xing
#

require 'tmpdir'
require_relative './string'
require_relative './my_file_utils'
require_relative './my_prompt'
require_relative './os'

# Cross-platform sudo: Windows has no sudo; Unix checks EUID.
SUDO = if OS.win?
  ''
else
  Process.euid == 0 ? '' : 'sudo'
end

# Execute a shell command with optional sudo and logging.
# Delegates to OS.sh_stream for cross-platform shell handling.
def ex(cmd, su: false, verbose: true)
  real_cmd = su ? "#{SUDO} #{cmd}".strip : cmd
  puts "#{Time.now.localtime.to_s.pink}\n>> #{real_cmd.yellow} <<" if verbose
  unless OS.sh_stream(real_cmd)
    raise "Command failed: #{real_cmd}"
  end
end

class App
  attr_reader :name, :min_ver

  def initialize(name, min_ver)
    @name = name
    @min_ver = min_ver
    @ver = nil
    @work_dir = nil
  end

  def install
    to_be_implemented
  end

  def version
    to_be_implemented
  end

  # Why this dependency is needed — override in subclasses.
  def reason
    nil
  end

  # Print a short explanation of why this dependency is required.
  def print_reason
    r = reason
    puts "  Reason: #{r}".yellow if r
  end

  # Read-only check: returns :ok, :missing, or :outdated (no install, no prompt).
  def check
    unless exist?
      return :missing
    end
    return :outdated if ver_too_low?
    :ok
  end

  def mksure
    is_fresh = false

    unless exist?
      print_reason
      MyPrompt.exit_unless_yes("#{@name} does not exist, install it?")
      install
      is_fresh = true
    end

    if ver_too_low? && !is_fresh
      print_reason
      MyPrompt.exit_unless_yes(
        "#{@name} version(#{@ver}) < required(#{@min_ver}), reinstall it?")
      reinstall
    end

    return unless ver_too_low?
    print_reason
    raise "Unable to install #{name} with version(#{@ver}) >= #{@min_ver}"
  end

  def exist?
    App.exist? @name
  end

  def install_from_mgr
    App.install_from_mgr @name
  end

  def reinstall
    App.uninstall_from_mgr @name
    install
  end

  def ver_too_low?
    @ver = version
    @ver.ver_less_than? @min_ver
  end

  def get_src_from_git(repo, tag)
    App.install_from_mgr 'git' unless App.exist? 'git'
    cd_work_dir(reset: true) do
      ex "git clone #{tag ? "--branch #{tag}" : ''} --depth=1 #{repo}"
    end
  end

  def get_src_from_url(url)
    App.install_from_mgr 'wget' unless App.exist? 'wget'
    cd_work_dir(reset: true) do
      ex "wget #{url}"
    end
  end

  # Download a file from url to dest. Uses open-uri (stdlib, no extra deps).
  def download_file(url, dest)
    require 'open-uri'
    FileUtils.mkdir_p(File.dirname(dest))
    URI.open(url, 'rb') do |remote|
      File.open(dest, 'wb') { |f| f.write(remote.read) }
    end
  end

  def cd_work_dir(reset: false)
    @work_dir ||= File.join(@@cache_dir, @name)
    if reset
      reset_dir @work_dir
    else
      make_sure_dir_exists @work_dir
    end
    FileUtils.cd @work_dir do
      yield
    end
  end

  class << self
    @@cache_dir = nil

    @@su = nil
    @@pkg_mgr = nil
    @@cmd_install = nil
    @@cmd_uninstall = nil
    @@opt_yes = nil

    def to_be_implemented
      raise 'To be implementd'
    end

    def set_cache_dir(dir)
      @@cache_dir = dir
      make_sure_dir_exists @@cache_dir
    end

    def get_cache_dir
      return @@cache_dir
    end

    # Cross-platform tool existence check — single source of truth in OS module.
    def exist?(name)
      OS.tool_available?(name)
    end

    # Null device path for stderr suppression.
    def devnull
      OS.win? ? 'nul' : '/dev/null'
    end

    def find_pkg_mgr
      unless @@pkg_mgr
        if exist? 'apt-get'
          @@su = true
          @@pkg_mgr='apt'
          @@cmd_install='install'
          @@cmd_uninstall='remove'
          @@opt_yes='-y'
        elsif exist? 'yum'
          @@su = true
          @@pkg_mgr='yum'
          @@cmd_install='install'
          @@cmd_uninstall='remove'
          @@opt_yes='-y'
        elsif exist? 'dnf'
          @@su = true
          @@pkg_mgr='dnf'
          @@cmd_install='install'
          @@cmd_uninstall='remove'
          @@opt_yes='-y'
        elsif exist? 'apk'
          @@su = true
          @@pkg_mgr='apk'
          @@cmd_install='add'
          @@cmd_uninstall='del'
          @@opt_yes=''
        elsif exist? 'brew'
          @@su = false
          @@pkg_mgr='brew'
          @@cmd_install='install'
          @@cmd_uninstall='uninstall'
          @@opt_yes=''
        else
          raise 'Unknown package manager!'
        end
      end
    end

    def install_from_mgr(name)
      find_pkg_mgr
      ex "#{@@pkg_mgr} #{@@cmd_install} #{@@opt_yes} #{name}", su: true
    end

    def uninstall_from_mgr(name)
      find_pkg_mgr
      ex "#{@@pkg_mgr} #{@@cmd_uninstall} #{@@opt_yes} #{name}", su: true
    end
  end
end

# ─── App subclasses ───────────────────────────────────────────────────────────
# Each subclass implements `install` and `version` for the App#mksure workflow.
# On Windows where package managers are unavailable, install prints a red
# download hint and raises — the user must install manually.

class AppGo < App
  def initialize(min_ver = '1.21')
    super('go', min_ver)
  end

  def reason
    'Go is the backend language; required to compile and run the server.'
  end

  def version
    ver = `go version 2>#{App.devnull}`.strip
    m = ver.match(/go(\d+\.\d+(\.\d+)?)/)
    m ? m[1] : '0.0'
  rescue
    '0.0'
  end

  def install
    if OS.win?
      puts "Go 1.21+：从 https://golang.org/dl/ 下载".red
      raise 'Go installation required — please install manually on Windows'
    elsif OS.mac?
      install_from_mgr
    else
      # Linux: golang package name varies by distro
      App.find_pkg_mgr
      case App.class_variable_get(:@@pkg_mgr)
      when 'apt' then ex "sudo apt update && sudo apt install -y golang-go"
      else install_from_mgr
      end
    end
  end
end

class AppGCC < App
  # TDM-GCC installer URLs by architecture.
  TDMGCC_URL_64 = 'https://github.com/jmeubank/tdm-gcc/releases/download/v10.3.0-tdm64-2/tdm64-gcc-10.3.0-2.exe'
  TDMGCC_URL_32 = 'https://github.com/jmeubank/tdm-gcc/releases/download/v10.3.0-tdm-1/tdm-gcc-10.3.0.exe'

  def initialize(min_ver = '0.0')
    super('gcc', min_ver)
  end

  def reason
    'GCC is required by CGO to compile go-sqlite3 (C-based SQLite driver).'
  end

  def version
    ver = `gcc --version 2>#{App.devnull}`.strip
    m = ver.match(/(\d+\.\d+(\.\d+)?)/)
    m ? m[1] : '0.0'
  rescue
    '0.0'
  end

  def install
    if OS.win?
      install_win
    elsif OS.mac?
      puts "Installing Xcode Command Line Tools…"
      system("xcode-select --install 2>/dev/null")
    else
      install_from_mgr
    end
  end

  private

  def install_win
    url = OS.win64? ? TDMGCC_URL_64 : TDMGCC_URL_32
    installer = File.join(Dir.tmpdir, File.basename(url))

    puts "  GCC not found. TDM-GCC installer can be downloaded automatically.".yellow
    puts "  URL: #{url}".yellow
    MyPrompt.exit_unless_yes("Download TDM-GCC installer to #{installer}?")

    puts "  Downloading TDM-GCC installer…"
    download_file(url, installer)
    puts "  Downloaded: #{installer}".green

    puts "  Launching installer — please complete the installation wizard.".yellow
    system("start \"\" \"#{installer.gsub('/', '\\\\')}\"")
    puts "  After installation, restart your terminal and re-run: rake be:env".yellow
    raise 'GCC installation pending — restart terminal after TDM-GCC setup'
  end
end

class AppNode < App
  def initialize(min_ver = '14')
    super('node', min_ver)
  end

  def reason
    'Node.js is required to build and run the React/TypeScript frontend.'
  end

  def version
    `node --version 2>#{App.devnull}`.strip.gsub(/^v/, '')
  rescue
    '0.0'
  end

  def install
    if OS.win?
      puts "Node.js 14+：从 https://nodejs.org/ 下载".red
      raise 'Node.js installation required — please install manually on Windows'
    elsif OS.mac?
      App.install_from_mgr('node')
    else
      # Linux: use NodeSource for up-to-date versions
      App.find_pkg_mgr
      case App.class_variable_get(:@@pkg_mgr)
      when 'apt'
        ex "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
        ex "sudo apt install -y nodejs"
      when 'yum', 'dnf'
        mgr = App.class_variable_get(:@@pkg_mgr)
        ex "curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -"
        ex "sudo #{mgr} install -y nodejs"
      else
        App.install_from_mgr('nodejs')
      end
    end
  end
end

class AppYarn < App
  def initialize(min_ver = '0.0')
    super('yarn', min_ver)
  end

  def reason
    'Yarn is used as the frontend package manager for faster dependency resolution.'
  end

  def version
    `yarn --version 2>#{App.devnull}`.strip
  rescue
    '0.0'
  end

  def install
    ex "npm install -g yarn"
  end
end

# SQLite prebuilt DLL + headers for Windows.
# go-sqlite3 CGO build needs sqlite3.h and sqlite3.dll in the compiler search path.
# On Unix, sqlite-dev is typically available via package manager; on Windows we
# download the official precompiled bundle from https://sqlite.org/download.html.
class AppSQLite < App
  # SQLite download page lists versioned zip files. We use a known-good version.
  # Update these URLs when upgrading SQLite.
  SQLITE_VER = '3490100'
  SQLITE_DLL_64  = "https://sqlite.org/2025/sqlite-dll-win-x64-#{SQLITE_VER}.zip"
  SQLITE_DLL_32  = "https://sqlite.org/2025/sqlite-dll-win-x86-#{SQLITE_VER}.zip"
  SQLITE_AMALG   = "https://sqlite.org/2025/sqlite-amalgamation-#{SQLITE_VER}.zip"

  def initialize(min_ver = '0.0')
    super('sqlite3', min_ver)
  end

  def reason
    'SQLite headers and DLL are needed by go-sqlite3 CGO build on Windows.'
  end

  # On Windows, check if sqlite3.h is reachable by GCC.
  def exist?
    return true unless OS.win?
    # Check if GCC can find sqlite3.h
    test_c = File.join(Dir.tmpdir, '_sqlite_test.c')
    File.write(test_c, '#include <sqlite3.h>')
    result = system("gcc -fsyntax-only \"#{test_c}\" 2>nul")
    FileUtils.rm_f(test_c)
    result
  end

  def version
    '0.0' # version check not critical; existence is enough
  end

  def install
    unless OS.win?
      # Unix: install via package manager (libsqlite3-dev / sqlite-devel)
      App.find_pkg_mgr
      case App.class_variable_get(:@@pkg_mgr)
      when 'apt'  then ex 'sudo apt install -y libsqlite3-dev'
      when 'yum', 'dnf'
        mgr = App.class_variable_get(:@@pkg_mgr)
        ex "sudo #{mgr} install -y sqlite-devel"
      when 'brew' then App.install_from_mgr('sqlite3')
      else App.install_from_mgr('sqlite3')
      end
      return
    end

    install_win
  end

  private

  def install_win
    # Determine GCC's search path — place files where GCC can find them.
    gcc_dir = detect_gcc_include_dir
    unless gcc_dir
      puts '  Cannot detect GCC include directory. Install GCC first.'.red
      raise 'GCC must be installed before SQLite headers'
    end

    include_dir = gcc_dir
    lib_dir     = File.join(File.dirname(gcc_dir), 'lib')
    bin_dir     = File.join(File.dirname(gcc_dir), 'bin')

    dll_url  = OS.win64? ? SQLITE_DLL_64 : SQLITE_DLL_32
    amalg_url = SQLITE_AMALG

    tmp = File.join(Dir.tmpdir, 'sqlite_setup')
    FileUtils.rm_rf(tmp)
    FileUtils.mkdir_p(tmp)

    puts "  Downloading SQLite DLL (#{OS.bits}-bit)..."
    dll_zip = File.join(tmp, 'sqlite_dll.zip')
    download_file(dll_url, dll_zip)

    puts '  Downloading SQLite amalgamation (headers)...'
    amalg_zip = File.join(tmp, 'sqlite_amalg.zip')
    download_file(amalg_url, amalg_zip)

    # Extract using PowerShell (available on all modern Windows).
    extract_zip(dll_zip, File.join(tmp, 'dll'))
    extract_zip(amalg_zip, File.join(tmp, 'amalg'))

    # Copy sqlite3.h to GCC include dir.
    header = Dir.glob(File.join(tmp, 'amalg', '**', 'sqlite3.h')).first
    if header
      FileUtils.cp(header, include_dir)
      puts "  Installed sqlite3.h → #{include_dir}".green
    else
      puts '  sqlite3.h not found in amalgamation zip'.red
    end

    # Copy sqlite3.dll to GCC bin dir (on PATH).
    dll = Dir.glob(File.join(tmp, 'dll', '**', 'sqlite3.dll')).first
    if dll
      FileUtils.mkdir_p(bin_dir)
      FileUtils.cp(dll, bin_dir)
      puts "  Installed sqlite3.dll → #{bin_dir}".green
    end

    # Generate import lib (sqlite3.def → libsqlite3.a) for static linking.
    deffile = Dir.glob(File.join(tmp, 'dll', '**', 'sqlite3.def')).first
    if deffile
      FileUtils.mkdir_p(lib_dir)
      lib_out = File.join(lib_dir, 'libsqlite3.a')
      system("dlltool -D sqlite3.dll -d \"#{deffile}\" -l \"#{lib_out}\" 2>nul")
      puts "  Generated #{lib_out}".green if File.exist?(lib_out)
    end

    FileUtils.rm_rf(tmp)
  end

  # Find GCC's default include directory.
  def detect_gcc_include_dir
    # Ask GCC for its search dirs.
    out = `gcc -print-search-dirs 2>nul`
    if out =~ /install:\s*(.+)/
      base = $1.strip.chomp('/').chomp('\\')
      inc = File.join(base, 'include')
      return inc if Dir.exist?(inc)
    end
    # Fallback: look for gcc.exe on PATH and use sibling include/.
    gcc_path = `where gcc 2>nul`.strip.split("\n").first
    if gcc_path && !gcc_path.empty?
      base = File.dirname(File.dirname(gcc_path))
      inc = File.join(base, 'include')
      return inc if Dir.exist?(inc)
      # TDM-GCC: <root>/include
      FileUtils.mkdir_p(inc)
      return inc
    end
    nil
  end

  def extract_zip(zip_path, dest)
    FileUtils.mkdir_p(dest)
    # Use PowerShell Expand-Archive — no extra dependencies.
    ps_cmd = "powershell -NoProfile -Command \"Expand-Archive -Force -Path '#{zip_path.gsub('/', '\\\\')}' -DestinationPath '#{dest.gsub('/', '\\\\')}'\"" 
    system(ps_cmd)
  end
end

class AppBrew < App
  def initialize(min_ver = '0.0')
    super('brew', min_ver)
  end

  def version
    ver = `brew --version 2>#{App.devnull}`.strip
    m = ver.match(/(\d+\.\d+(\.\d+)?)/)
    m ? m[1] : '0.0'
  rescue
    '0.0'
  end

  def install
    if OS.mac?
      ex '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
      ENV["PATH"] = "/opt/homebrew/bin:#{ENV['PATH']}"
    else
      raise 'Homebrew is only supported on macOS'
    end
  end
end
