require "open3"
require "rbconfig"
require "shellwords"

module OS
  @@uname = nil

  class << self
    KNOWN = %w[linux mac win android iphoneos iphonesimulator].freeze

    def win?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def mac?
      (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def unix?
      !win?
    end

    def linux?
      unix? && !mac?
    end

    def old_centos?
      uname && (uname =~ /centos.+tlinux/)
    end

    def jruby?
      RUBY_ENGINE == "jruby"
    end

    def is_known?(os)
      KNOWN.include?(os)
    end

    def uname
      return nil unless unix?
      @@uname ||= `uname -a`
    end

    def local
      if mac?    then "mac"
      elsif linux? then "linux"
      elsif win?   then "win"
      end
    end

    def available_memory_mb
      if linux?
        meminfo = File.read("/proc/meminfo") rescue nil
        if meminfo
          m = meminfo.match(/MemAvailable:\s+(\d+)\s+kB/)
          return m[1].to_i / 1024 if m
        end
      elsif mac?
        out = `vm_stat 2>/dev/null`
        page_size = 4096
        free_pages     = out.match(/Pages free:\s+(\d+)/)&.captures&.first.to_i
        inactive_pages = out.match(/Pages inactive:\s+(\d+)/)&.captures&.first.to_i
        return (free_pages + inactive_pages) * page_size / (1024 * 1024)
      elsif win?
        out = `wmic OS get FreePhysicalMemory /Value 2>nul`
        m = out.match(/FreePhysicalMemory=(\d+)/)
        return m[1].to_i / 1024 if m
      end
      1024
    end

    # Returns the host GOARCH string for CGO builds.
    def goarch
      arch = RbConfig::CONFIG["host_cpu"]
      case arch
      when /arm64|aarch64/ then "arm64"
      when /x86_64|amd64/  then "amd64"
      when /i[3-6]86/      then "386"
      else arch
      end
    end

    # CGO env vars for `go run` / `go build` on the current host.
    def cgo_env
      goos = mac? ? "darwin" : linux? ? "linux" : win? ? "windows" : local
      { "CGO_ENABLED" => "1", "GOOS" => goos, "GOARCH" => goarch }.freeze
    end

    def tool_available?(name)
      if win?
        system("where #{Shellwords.escape(name)} >nul 2>nul")
      else
        system("command -v #{Shellwords.escape(name)} >/dev/null 2>&1")
      end
    end

    def port_in_use?(port)
      if win?
        out = `netstat -ano 2>nul`
        out.include?(":#{port} ") && out =~ /:#{port}\s+.*LISTENING/
      else
        system("lsof -i :#{port} -sTCP:LISTEN -t >/dev/null 2>&1")
      end
    end

    def pids_on_port(port)
      if win?
        out = `netstat -ano 2>nul`
        pids = []
        out.each_line do |line|
          next unless line =~ /:#{port}\s+.*LISTENING\s+(\d+)/
          pids << $1.to_i
        end
        pids.uniq
      else
        out, = Open3.capture2("lsof -i :#{port} -sTCP:LISTEN -t 2>/dev/null")
        out.split.map(&:strip).reject(&:empty?).map(&:to_i)
      end
    end

    # Kill processes matching a command-line pattern.
    def pkill_pattern(pattern, label, kill_fn)
      if win?
        out, = Open3.capture2("wmic process where \"CommandLine like '%#{pattern}%'\" get ProcessId 2>nul")
        pids = out.scan(/\d+/).map(&:to_i).reject(&:zero?)
      else
        out, = Open3.capture2("pgrep -f #{Shellwords.escape(pattern)} 2>/dev/null")
        pids = out.split.map(&:to_i).reject(&:zero?)
      end
      return if pids.empty?

      kill_fn.call(pids, label)
    end

    # TCP reachability check (port 443 by default, 3-second timeout).
    def host_reachable?(host, port: 443, timeout: 3)
      require "socket"
      Socket.tcp(host, port, connect_timeout: timeout) { true }
    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError, Errno::EHOSTUNREACH
      false
    end

    # Stream a shell command, inheriting stdout/stderr.
    def sh_stream(cmd, env: {})
      merged = ENV.to_h.merge(env)
      if win?
        IO.popen([merged, "cmd", "/c", cmd], err: [:child, :out]) { |io| io.each { |l| print l } }
      else
        IO.popen([merged, "bash", "-c", cmd], err: [:child, :out]) { |io| io.each { |l| print l } }
      end
      $?.success?
    end
  end
end