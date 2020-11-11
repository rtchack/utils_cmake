#
# Created by xing
#

require_relative '../utils/app_kit'

class CmakeApp < App
  def initialize
    super 'cmake', '3.10'
  end

  def install
    install_from_mgr
  end

  def reinstall
    App.uninstall_from_mgr @name

    get_src_from_git 'https://github.com/Kitware/CMake.git', 'v3.12.3'

    FileUtils.cd File.join(@work_dir, 'CMake') do
      ex './configure && make -j$(nproc)'
      ex 'make install', su: true
    end
  end

  def version
    %x(cmake --version)[/^cmake +version +(\d+\.\d+\.\d+)/, 1]
  end
end

def prepare_cmake(root_dir)
  return if OS.win?
  CmakeApp.new.mksure
end
