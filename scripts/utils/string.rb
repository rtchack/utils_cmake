#
# Created by xing in 2019
#

class String
  def camelize
    split('_').collect(&:capitalize).join
  end

  def underscore
    gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z\d])([A-Z])/, '\1_\2').
      tr("-", "_").
      downcase
  end

  # Truncate to +len+ chars (default: Conf[:preview_len]).
  def preview(len = Conf[:preview_len])
    return self if length <= len
    self[0, len]
  end

  # Semantic version comparison: is self < second?
  # e.g. "1.20".ver_less_than?("1.21") => true
  def ver_less_than?(second)
    v1 = split(/ *\. */)
    v2 = second.split(/ *\. */)

    0.upto [v1.size, v2.size].min do |i|
      return false if v1[i].to_i > v2[i].to_i
      return true if v1[i].to_i < v2[i].to_i
    end

    v1.size < v2.size
  end

  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def gray
    colorize(90)
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def magenta
    colorize(35)
  end

  def bright_magenta
    colorize(95)
  end

  def light_blue
    colorize(94)
  end

  def cyan
    colorize(36)
  end

end
