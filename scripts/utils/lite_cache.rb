#
# Created by xing in 2021.
#

require 'yaml'

# LiteCache checker
class LiteCache
  def initialize(file_name)
    @cache_file = file_name

    @old = File.exist?(@cache_file) ? YAML.load(File.read @cache_file) : nil
    @current = @cache
    puts "Cache: #{@old}.".light_blue
  end

  def get(key)
    raise "No cache for '#{key}'" unless @current && @current[key]
    @current[key]
  end

  def set(key, value)
    return if @current && @current[key] == value
    @current = {} unless @current
    @current[key] = value
    File.write @cache_file, @current.to_yaml
    value
  end

  def on(key, value)
    return get(key) unless value
    set key, value
  end

  def any_updated?(*keys)
    return false unless @current

    keys.each do |k|
      return true if @current[k] != @old[k]
    end
    false
  end

end


