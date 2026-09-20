# frozen_string_literal: true
#
# Helpers for tests that drive real ``git`` subprocesses against throwaway
# repos. Extracted because two suites (``tools/dandelion/robot.test.rb``,
# ``tools/tasks/git.cleanup.test.rb``) hit the same trap: a developer's
# global ``core.hooksPath`` (security software push interception, custom
# ``~/.git-hooks/pre-push``, …) is inherited by every tmpdir repo and can
# make ``git push`` block on a handshake that never completes, so the
# suite hangs. These helpers isolate the test repos from that.

module GitTest
  module_function

  # Neutralise a globally-configured ``core.hooksPath`` for one repo so a
  # stray ``pre-push`` / ``pre-receive`` from the user's machine cannot
  # block or alter test pushes. Pointed at ``/dev/null`` (empty hooks dir)
  # rather than unset, which is the most explicit "run no hooks here".
  # Call after the repo is created (``git init`` / ``git clone``) and
  # before any ``git push``.
  def silence_global_hooks(work_dir)
    `git -C #{work_dir} config core.hooksPath /dev/null 2>/dev/null`
  end
end
