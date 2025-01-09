#
# Created by xing
#

require_relative '../utils/app_kit'

class GitApp < App
  def initialize
    super 'git', '0'
  end

  def isntall
    install_from_mgr
  end

  def reinstall
    App.uninstall_from_mgr @name

    get_src_from_url 'https://github.com/git/git/archive/v2.25.4.tar.gz'

    FileUtils.cd @work_dir do
      ex 'tar -xf v2.25.4.tar.gz'
    end

    FileUtils.cd File.join(@work_dir, 'git-2.25.4') do
      ex 'make -j$(nproc)'
      ex 'make install', su: true
    end
  end

  def version
    %x(git --version)[/^git +version +(\d+\.\d+\.\d+)/, 1]
  end
end

def prepare_git(root, hooks)
  return if OS.win?

  GitApp.new.mksure

  return unless hooks.size > 0

  hook_dir = "#{root}/.git/hooks"
  FileUtils.cd hook_dir, verbose: false do
    hooks.each do |k, v|
      k_file = "#{hook_dir}/#{k}"
      unless File.exist?(k_file) &&
          File.symlink?(k_file) &&
          File.readlink(k_file) == v
        if File.exist?(k_file) || File.symlink?(k_file)
          mv k_file, "#{k_file}.old", verbose: true
        end
        File.symlink v, k
      end
      (raise $? unless system "chmod +x #{k}") unless File.executable?(k_file)
    end
  end
end
