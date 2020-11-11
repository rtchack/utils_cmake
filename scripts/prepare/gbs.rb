#
# Created by xing
#

require_relative '../utils/app_kit'
require_relative '../utils/old_centos'

class AutoconfApp < App
  def initialize
    super 'autoconf', '0'
  end

  def install
    install_from_mgr
  end

  def version
    '1'
  end
end

class AutomakeApp < App
  def initialize
    super 'automake', '0'
  end

  def install
    install_from_mgr
  end

  def version
    '1'
  end
end

class GccApp < App
  def initialize
    super 'gcc', '5'
  end

  def version
    %x(gcc --version)[/^gcc +.+(\d+\.\d+\.\d+)/, 1]
  end

  def install
    LibtoolApp.new.mksure
    update_old_centos_devtools || return if OS.old_centos?
    install_from_mgr
  end

  def reinstall
    update_old_centos_devtools if OS.old_centos?
  end
end

class GppApp < App
  def initialize
    super 'g++', '5'
  end

  def version
    %x(g++ --version)[/^g\+\+ +.+(\d+\.\d+\.\d+)/, 1]
  end

  def install
    LibtoolApp.new.mksure
    update_old_centos_devtools || return if OS.old_centos?

    begin
      App.install_from_mgr 'gcc-c++'
    rescue
      install_from_mgr
    end
  end

  def reinstall
    update_old_centos_devtools if OS.old_centos?
  end
end

def prepare_gbs
  return if OS.win?

  AutoconfApp.new.mksure
  AutomakeApp.new.mksure

  return unless OS.linux?
  GccApp.new.mksure
  GppApp.new.mksure
end
