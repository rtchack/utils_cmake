#
# Created by xing
#

require_relative '../utils/app_kit'
require_relative '../utils/old_centos'

class ClangApp < App
  def initialize
    super 'clang', '6'
  end

  def version
    %x(clang --version)[/clang +version +(\d+\.\d+\.\d+)/, 1]
  end

  def install
    install_from_mgr
  end

  def reinstall
    update_old_centos_devtools if OS.old_centos?
  end
end

class ClangFormatApp < App
  def initialize
    super 'clang-format', '6'
  end

  def version
    %x(clang-format --version)[/version +(\d+\.\d+\.\d+)/, 1]
  end

  def install
    install_from_mgr
  end

  def reinstall
    update_old_centos_devtools if OS.old_centos?
  end
end


def prepare_clang
  return if OS.win?

  ClangApp.new.mksure
  ClangFormatApp.new.mksure
end

