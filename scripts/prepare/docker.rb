#
# Created by xing
#

require_relative '../utils/app_kit'

class DockerApp < App
  def initialize
    super 'docker', '19'
  end

  def install
    install_from_mgr
  end

  def version
    %x(docker --version)[/^Docker +version +(\d+\.\d+\.\d+)/, 1]
  end
end

def prepare_docker
  return if OS.win?
  DockerApp.new.mksure
end
