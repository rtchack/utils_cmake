#
# Created by xing
#

class MyPrompt
  class << self
    @@interactive = true

    def exit_unless_yes(prompt)
      return unless @@interactive
      # Without a TTY, gets either blocks forever (open pipe, no writer) or
      # returns nil at EOF — nil.chomp then crashes. Bail with a clear message
      # instead of hanging or stack-tracing.
      unless STDIN.tty?
        abort "  non-interactive stdin — cannot prompt \"#{prompt}\"; " \
              "re-run in a terminal or set DANDELION_ENV_NONINTERACTIVE=1.".red
      end
      print "(#{prompt}) `y` to continue, [Y/n]: "
      input = STDIN.gets
      exit 1 unless input && input.chomp =~ /^(y|Y)$/
    end

    def set_interactivity(be_interactive)
      @@interactive = be_interactive
    end
  end
end
