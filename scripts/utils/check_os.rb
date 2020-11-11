#
# Created by xing
#

# Check OS
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
        #Unknown
        nil
      end
    end
  end
end
