#
# Created by xing
#

require_relative './colorful_str'
require_relative './my_file_utils'
require_relative './my_prompt'
require_relative './check_os'

SUDO = %x(echo $EUID) =~ /^0$/ ? '' : 'sudo'

def ex(cmd, su: false, verbose: true)
  real_cmd = su ? "#{SUDO} #{cmd}" : cmd
  puts "#{Time.now.localtime.to_s.pink}\n>> #{real_cmd.yellow} <<" if verbose
  raise %x($?) unless system real_cmd
end

class String
  def ver_less_than?(second)
    v1 = split(/ *\. */)
    v2 = second.split(/ *\. */)

    0.upto [v1.size, v2.size].min do |i|
      return false if v1[i].to_i > v2[i].to_i
      return true if v1[i].to_i < v2[i].to_i
    end

    v1.size < v2.size
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

  def mksure
    is_fresh = false

    unless exist?
      MyPrompt.exit_unless_yes("#{@name} does not exist, install it?")
      install
      is_fresh = true
    end

    if ver_too_low? && !is_fresh
      MyPrompt.exit_unless_yes(
        "#{@name} version(#{@ver}) < required(#{@min_ver}), reinstall it?")
      reinstall
    end

    return unless ver_too_low?
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

    def exist?(name)
      # Don't know why `command -v` does not work here,
      # use `which` instead
      system "which #{name}"
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
