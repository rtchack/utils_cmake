#
# Created by xing
#

require 'fileutils'

def make_sure_dir_exist(name)
  if File.exist? name
    raise "#{name} should be a dir!" unless File.directory? name
  else
    FileUtils.mkdir_p name
  end
end

def reset_dir(name)
  if File.exist?(name)
    raise "#{name} should be a dir!" unless File.directory? name
    FileUtils.rm_r name, verbose: true
  end
  FileUtils.mkdir_p name, verbose: true
end

def file_num(dir)
  n = 0

  Dir.foreach dir do |f|
    next if f =~ /^\.\.?$/

    f = File.join dir, f
    if File.directory? f
      n += file_num f
    else
      n += 1
    end
  end

  return n
end

def each_file(dir)
  Dir.foreach dir do |f|
    next if f =~ /^\.\.?$/

    f = File.join dir, f
    if File.directory? f
      each_src f do |local_f|
        yield local_f
      end
    else
      yield f
    end
  end
end

def each_src(dir)
  each_file(dir) do |f|
    next unless f =~ /\.(h|hh|hpp|c|cc|cpp|cxx)$/
    yield f
  end
end
