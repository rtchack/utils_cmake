#
# Created by xing
#

class MyPrompt
  class << self
    @@interactive = true

    def exit_unless_yes(prompt)
      return unless @@interactive
      print "(#{prompt}) `y` to continue, [Y/n]: "
      exit 1 unless STDIN.gets.chomp =~ /^(y|Y)$/

    end

    def set_interactivity(be_interactive)
      @@interactive = be_interactive
    end
  end
end
