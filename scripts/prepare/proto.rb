#
# Created by xing
#

require_relative '../utils/app_kit'

class ProtocApp < App
  def initialize(root)
    @cmake_dir = File.join root, 'third_party', 'protobuf', 'cmake'
    super 'protoc', '3'
  end

  def version
    %x(protoc --version)[/^libprotoc +(\d+\.\d+\.\d+)/, 1]
  end

  def install
    cd_work_dir do
      ex "cmake -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_BUILD_EXAMPLES=OFF #{@cmake_dir}"
      ex 'cmake --build . --target protoc -- -j$(nproc)'
      ex 'cmake --build . --target libprotobuf-lite -- -j$(nproc)'
      ex 'cmake --build . --target install', su: true
    end
  end
end

class ProtoccApp < App
  def initialize(root)
    @cmake_dir = File.join root, 'third_party', 'protobuf-c', 'build-cmake'
    super 'protoc-c', '1.3'
  end

  def version
    %x(protoc-c --version)[/^protobuf-c +(\d+\.\d+\.\d+)/, 1]
  end

  def install
    cd_work_dir do
      build_dir = File.join @work_dir, 'protobuf-c', 'build'
      reset_dir build_dir
      FileUtils.cd build_dir, verbose:true do
         ex "cmake #{@cmake_dir}"
         ex 'cmake --build . -- -j$(nproc)'
         ex 'cmake --build . --target install', su: true
      end
    end
  end
end

def prepare_proto(root)
  return unless OS.win?
  ProtocApp.new(root).mksure
  ProtoccApp.new(root).mksure
end
