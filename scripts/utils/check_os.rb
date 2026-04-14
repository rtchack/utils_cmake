#
# Created by xing
#

module OS
  @@uname = nil # Unix only

  class << self
    KNOWN = %w(linux mac win android iphoneos iphonesimulator)

    def win?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def mac?
     (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    def unix?
      !OS.win?
    end

    def linux?
      OS.unix? and not OS.mac?
    end

    def old_centos?
      uname && (uname =~ /centos.+tlinux/)
    end

    def jruby?
      RUBY_ENGINE == 'jruby'
    end

    def is_known?(os)
      KNOWN.include? os
    end

    def uname
      return nil unless unix?
      @@uname ||= %x(uname -a)
    end

    def local
      if mac?
        'mac'
      elsif linux?
        'linux'
      elsif win?
        'win'
      else
        nil
      end
    end

    # Available physical memory in MB (falls back to 1024).
    def available_memory_mb
      if linux?
        meminfo = File.read('/proc/meminfo') rescue nil
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
  end
end
