#
# Created by xing in 2021.
#

require 'yaml'

# LiteCache checker
class LiteCache
  def initialize(file_name)
    @cache_file = file_name

    @old = File.exist?(@cache_file) ? YAML.load(File.read @cache_file) : nil
    @current = @old || {}
    puts "Cache: #{@old}.".light_blue
  end

  def get(key)
    @current[key]
  end

  def set(key, value)
    if !value
      return @current.delete(key) if @current.key? key
      return nil
    end

    return value if @current && @current[key] == value
    @current = {} unless @current
    @current[key] = value
    File.write @cache_file, @current.to_yaml
    value
  end

  def on(key, value)
    return set(key, value) if value

    value = get key
    raise "Value not set for '#{key}'" unless value
    value
  end

  def any_updated?(*keys)
    return false unless @current

    keys.each do |k|
      return true if @current[k] != @old[k]
    end
    false
  end

end


