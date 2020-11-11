#
# Created by xing
#

require_relative 'check_os'

def update_old_centos_devtools
  return unless OS.old_centos?

  ex 'yum -y install centos-release-scl'
  ex 'yum -y install devtoolset-8 llvm-toolset-7.0', su: true
  ex "yum -y install llvm-toolset-7.0-clang-analyzer \
llvm-toolset-7.0-clang-tools-extra", su: true
  File.open File.join(ENV['HOME'], '.bashrc'), 'a' do |f|
    f.puts 'source scl_source enable devtoolset-8 llvm-toolset-7.0'
  end
  puts 'Now you can rerun your last command.'
  ex 'scl enable devtoolset-8 llvm-toolset-7.0 bash', su: true
end
