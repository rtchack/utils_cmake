#
# Created by xing in 2020.
#

SCRIPT_DIR = File.dirname __FILE__

%w[ app_kit
    extract_ngx_checks
    check_os
    my_file_utils
    docker
    proto
    lite_cache].each do |s| 
      require File.join(SCRIPT_DIR, 'utils', s)
end

%w[ clang
    cmake
    docker
    gbs
    git
    proto ].each do |s| 
      require File.join(SCRIPT_DIR, 'prepare', s)
end

$root_dir = nil
$build_dir = nil
$app_cache_dir = nil
$dft_bin = nil
$dft_test = nil
$common_prepares = [:'prepare:git', :'prepare:cmake']
$docker = nil

# Set up root dir
def set_root_dir(dir)
  $root_dir = dir
  $build_dir = File.join dir, 'build'
  $app_cache_dir = File.join dir, '.app_cache'

  App.set_cache_dir $app_cache_dir
  MyPrompt.set_interactivity(false) if ENV['NONINTERACTIVE']
end

# Set up default targets
def set_default_targets(bin: nil, test: nil)
  $dft_bin = bin
  $dft_test = test
end

# ['clang', 'gbs', ...]
def set_tool_sets(tool_sets)
  tool_sets.each do |tool|
    $common_prepares << "prepare:#{tool}".to_sym
  end
end

# Set up source file number
def set_src_file_num(num)
  $src_file_num = num
end

# Use protobuf
def use_proto
  $common_prepares << :'prepare:proto'
end

# Use docker
def use_docker(pkg_name: nil, pkg_ver: nil, in_port: 0, out_port: 0)
  $docker = Docker::new(pkg_name, pkg_ver, in_port, out_port)
  prepare_docker
end


HISTORY_FILE = File.join SCRIPT_DIR, '.rake_history'
$history = LiteCache.new HISTORY_FILE

def cd_build_dir(type)
  dir = File.join $build_dir, type
  make_sure_dir_exists dir
  cd dir, verbose: true do
    yield
  end
end

def generate(type)
  cd_build_dir type do
    return if File.exist?('CMakeCache.txt') &&
              !$history.updated?(:n_src_files) &&
              !$history.get(:cmake_failed) &&
              !$history.updated?(:last_git_rev)

    begin
      case OS.local
      when /^(linux|mac|win)$/
        ex "cmake #{$root_dir} -DCMAKE_BUILD_TYPE=#{type.capitalize}"
      else
        ex "cmake #{$root_dir} -DCMAKE_BUILD_TYPE=#{type.capitalize}"
      end
    rescue
      $history.set :cmake_failed, true
      raise $?
    end
    $history.set :cmake_failed, false
  end 
end

def build(target, type: 'release', verb: false, run: false)
  cd_build_dir type do
    begin
    case OS.local
      when /^(linux|mac)$/
        ex "cmake --build . \
--target #{target} \
-- -j$(nproc) #{verb ? 'VERBOSE=1' : ''}"
      else
        ex "cmake --build . \
--target #{target} \
--config #{type.capitalize} --verbose #{verb ? 'VERBOSE=1' : ''}"
      end
    rescue
      $history.set :cmake_failed, true
      raise $?
    end
    $history.set :cmake_failed, false

    ex "$(find . -type f -name #{target})" if run
  end
end


def bar(title)
  puts "\n#{'=' * 30} #{title} #{'=' * 30}"
end

def non_supported_os
  raise "Non-supported OS #{OS.local}"
end

namespace :prepare do
  task :clang do
    prepare_clang
  end

  # GNU Build System
  task :gbs do
    prepare_gbs
  end

  task :cmake do
    prepare_cmake $root_dir
  end

  task :git do
    prepare_git($root_dir,
                'pre-commit' => File.join(SCRIPT_DIR, 'hooks', 'pre-commit'),
                'pre-push' => File.join(SCRIPT_DIR, 'hooks', 'pre-push')
               )
  end

  task :proto => [:cmake, :git, :gbs] do
    prepare_proto File.join($root_dir, 'third_party', 'protobuf')
  end

end

namespace :utils do
  task :gen_cmake_checks => :'prepare:clang' do
    extract_ngx_checks $root_dir do |f|
        ex "clang-format -style=file -i #{f}"
    end
  end

  task :git_format => [:'prepare:git', :'prepare:clang'] do
    cd $root_dir, verbose: false do
      %x(git diff --name-only --cached).split(/\n/).each do |f|
        next if f =~ /^(ngx|protocol|third_party)/
        next unless f =~ /\.(h|hh|hpp|c|cc|cpp|cxx)$/
        next unless File.exist? f
        ex("clang-format -style=file -i #{f} && git add #{f}", verbose: false)
      end
    end
  end

  # Format all sources
  task :format => :'prepare:clang' do
    %w[bin src].each do |dir|
      each_src(dir) do |f|
        ex "clang-format -style=file -i #{f}"
      end
    end
  end

  task :check_format => :'prepare:clang' do
    %w[bin src].each do |dir|
      each_src(dir) do |f|
        raise 'Plz run \'rake utils:format\' before push!' if system(
          "clang-format -output-replacements-xml \
-style=file #{f} | grep '<replacement '")
      end
    end
    puts 'Seems good!'
  end

  task :lint do
    #TODO(xing)
  end
end

namespace :docker do
  task :exists do
    raise 'Docker not enabled!' unless $docker
  end

  desc 'Build docker image'
  task :build => [:exists] do
    $docker.build
  end

  desc 'Run docker'
  task :run => [:exists] do
    $docker.run
  end

  desc 'Stop docker'
  task :stop => [:exists] do
    $docker.stop
  end
end

namespace :debug do
  task :generate => $common_prepares do
    generate 'debug'
  end

  desc 'Just build'
  task :build, [:what, :be_verb] => :generate do |_t, args|
    args.with_defaults what: $dft_bin
    build args.what, type: 'debug', verb: args.be_verb
  end

  desc 'Test'
  task :test, [:what, :be_verb] => :generate do |_t, args|
    args.with_defaults what: $dft_test
    build "test_#{args.what}", type: 'debug', verb: args.be_verb, run: true
  end

  desc 'Clean up'
  task :clean => :generate do
    build :clean, type: 'debug'
  end
end

namespace :release do
  task :generate => $common_prepares do
    generate 'release'
  end

  task :build, [:what, :be_verb] => :generate do |_t, args|
    args.with_defaults what: $dft_bin
    build args.what, verb: args.be_verb
  end

  task :test, [:what, :be_verb] => :generate do |_t, args|
    args.with_defaults what: $dft_test
    build "test_#{args.what}", verb: args.be_verb, run: true
  end

  task :clean => :generate do
    build :clean
  end
end

desc 'Clean up all'
task :clean_all do
  rm_r($build_dir, verbose: true) if File.exist? $build_dir
  rm_r($app_cache_dir, verbose: true) if File.exist? $app_cache_dir
end

desc 'Status.'
task :status do
  ex 'git status'
  bar 'Submodules'
  ex 'git submodule foreach "git status"'
end

desc 'Just build'
task :build, [:what, :be_verb] => :'release:build'

desc 'Test'
task :test, [:what, :be_verb] => :'release:test'

desc 'clean up'
task :clean => :'release:clean'

task :default => :build

