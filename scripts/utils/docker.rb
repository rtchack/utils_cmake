#
# Created by xing
#

require_relative 'os'
require_relative 'string'
# ``app_kit`` gives us ``App.devnull`` (used by :meth:`start!` to muffle
# the ``open -a Docker`` command); guarded elsewhere against circular
# require. Kept last so the ordering matches the load path other tools
# under tools/utils/ rely on.
require_relative 'app_kit'

class Docker
  # Timing knobs for :meth:`Docker.start!`. Declared at class level
  # (not inside ``class << self``) so both singleton methods and any
  # future instance-side helpers can reach them via the ``Docker::``
  # namespace. Kept as plain constants because they never vary at
  # runtime and a per-call keyword argument in ``wait_for_daemon``
  # already lets callers override the poll window when needed.
  START_TIMEOUT_SEC = 90
  START_POLL_INTERVAL_SEC = 1.0

  class << self
    # Returns the detected runtime name, or nil if none available
    def name
      @name ||= detect_name
    end

    # Returns true if any supported container runtime is available
    def available?
      !name.nil?
    end

    # Returns the docker-compose compatible command string, or nil
    def compose_cmd
      @compose_cmd ||= detect_compose_cmd
    end

    # Returns the base runtime command (docker/podman)
    def cmd
      case name
      when "Docker", "Colima"
        "docker"
      when "Podman"
        "podman"
      end
    end

    # Returns true when SOME container runtime is *installed* on the host,
    # regardless of whether its daemon is currently up. Used by
    # ``rake be:monitor:env`` — env-time only cares about "can we start
    # a daemon later", not "is it up right now"; the daemon is spun up
    # on demand by :meth:`start!` from ``rake be:monitor:run``. Keeping
    # env-time cheap (no docker info handshake) means the check works
    # in offline / laptop-just-woke-up scenarios that would otherwise
    # abort with "daemon not running" and force a manual start before
    # the user has even asked to run anything.
    #
    # Detection surface (matches :meth:`ensure!`'s branches):
    #   * ``docker`` / ``podman`` binary on PATH  → installed
    #   * mac: ``/Applications/Docker.app`` present → Docker Desktop
    #     installed (its GUI may add the CLI later on first launch)
    #   * mac: ``colima`` binary on PATH → colima installed
    #
    # We deliberately do NOT check daemon reachability here — the whole
    # point of splitting ``installed?`` off from ``available?`` is to
    # avoid the daemon poke.
    def installed?
      return true if cmd_exist?("docker") || cmd_exist?("podman")
      return true if OS.mac? && (docker_desktop_installed? || cmd_exist?("colima"))
      false
    end

    # Best-effort: make sure a container daemon is running, starting one
    # if a supported runtime is installed but idle. Called by
    # ``rake be:monitor:run`` so the user does not have to remember to
    # ``colima start`` / open Docker Desktop before every session.
    #
    # Platform behaviour:
    #   * mac  — if colima is installed, prefer it (``colima start`` is
    #     idempotent and reasonably fast); else fall back to opening
    #     Docker Desktop via ``open -a Docker`` and polling the daemon.
    #     We poll ``docker info`` for up to _START_TIMEOUT_SEC because
    #     the app's daemon takes 5-30s to be reachable after ``open``.
    #   * linux / win — do NOT auto-run ``sudo systemctl start docker``
    #     or ``systemctl --user start podman.socket``: rake is a
    #     dev-time tool and stealing a sudo prompt mid-session is worse
    #     than a clear failure message. Delegate to :meth:`ensure!`
    #     which prints the exact command the user should run.
    #
    # Return value: nil on success (or when the daemon was already up).
    # Aborts (via :meth:`ensure!`) when nothing supported is installed.
    def start!
      return if available?  # daemon already up — nothing to do

      unless installed?
        # No runtime at all — reuse the install guidance from ensure!.
        ensure!
        return
      end

      if OS.mac?
        # Prefer colima on mac: brew installs put it on PATH and
        # ``colima start`` is idempotent (returns 0 if already running).
        # This matches the "install colima first if you don't have
        # Docker Desktop" advice we give in :meth:`ensure!`.
        if cmd_exist?("colima")
          puts "  container runtime: starting Colima...".cyan
          system("colima start")  # deliberately non-fatal; we poll below
          if wait_for_daemon
            reset_detection!
            puts "  container runtime: Colima up (docker socket reachable)".green
            return
          end
        elsif docker_desktop_installed?
          puts "  container runtime: opening Docker Desktop...".cyan
          system("open -a Docker >#{App.devnull} 2>&1")
          if wait_for_daemon
            reset_detection!
            puts "  container runtime: Docker Desktop up".green
            return
          end
        end
        # We tried and the daemon still is not up. Let ensure! print
        # the exact command the user should run next.
        ensure!
      else
        # linux / windows — do not steal a sudo / UAC prompt; ensure!
        # already knows the correct start command per platform.
        ensure!
      end
    end

    # Reset memoised runtime detection so a fresh detect_name runs
    # after we changed daemon state (e.g. after :meth:`start!`).
    # ``@name`` and ``@compose_cmd`` are lazily set the first time the
    # accessor runs, so wiping them forces the next call to redetect.
    def reset_detection!
      @name = nil
      @compose_cmd = nil
    end

    # Abort with a helpful install hint if no runtime found
    def ensure!
      return if available?

      if OS.win?
        if cmd_exist?("docker") && !docker_running?
          abort_not_running("Docker Desktop", "Open Docker Desktop and wait for it to start")
        elsif cmd_exist?("podman") && !podman_running?
          abort_not_running("Podman", "podman machine init   # (first time only)\n    podman machine start")
        else
          abort_not_installed(
            "    • Docker Desktop : https://www.docker.com/products/docker-desktop\n" \
            "    • Podman Desktop : https://podman-desktop.io"
          )
        end
      elsif OS.mac?
        if docker_desktop_installed? && !docker_running?
          abort_not_running("Docker Desktop", "Open Docker Desktop and wait for it to start")
        elsif cmd_exist?("colima") && !colima_running?
          abort_not_running("Colima", "colima start")
        elsif cmd_exist?("podman") && !podman_running?
          abort_not_running("Podman", "podman machine init   # (first time only)\n    podman machine start")
        elsif cmd_exist?("docker") && !docker_running?
          abort_not_running("container runtime", "start your container runtime (OrbStack, Rancher Desktop, etc.)")
        else
          abort_not_installed(
            "    • Docker Desktop : https://www.docker.com/products/docker-desktop\n" \
            "    • Colima (brew)  : brew install colima docker && colima start\n" \
            "    • Podman Desktop : https://podman-desktop.io"
          )
        end
      else
        if cmd_exist?("docker") && !docker_running?
          abort_not_running("Docker", "sudo systemctl start docker")
        elsif cmd_exist?("podman") && !podman_running?
          abort_not_running("Podman", "systemctl --user start podman.socket")
        else
          abort_not_installed(
            "    • Docker Engine  : https://docs.docker.com/engine/install/\n" \
            "    • Podman         : https://podman.io/getting-started/installation"
          )
        end
      end
    end

    private

    def abort_not_running(runtime, start_cmd)
      puts "\n❌ #{runtime} is installed but not running.".red
      puts "\n  Please start it first:"
      puts "    #{start_cmd}"
      puts
      abort
    end

    def abort_not_installed(install_hints)
      puts "\n❌ No container runtime found.".red
      puts "\n  Please install one of the following:"
      puts install_hints
      puts
      abort
    end

    def cmd_exist?(cmd)
      if OS.win?
        system("where.exe #{cmd} >NUL 2>NUL")
      else
        system("which #{cmd} > /dev/null 2>&1")
      end
    end

    # Check if docker daemon is actually running (not just installed)
    def docker_running?
      if OS.win?
        system("docker info >NUL 2>NUL")
      else
        system("docker info > /dev/null 2>&1")
      end
    end

    # Check if podman service is running
    def podman_running?
      if OS.win?
        system("podman info >NUL 2>NUL")
      else
        system("podman info > /dev/null 2>&1")
      end
    end

    def detect_name
      # 1. Docker (Desktop or Engine) — check daemon is running
      if cmd_exist?("docker") && docker_running?
        return "Docker"
      end


      # 2. On Windows: Podman as Docker Desktop alternative
      if OS.win? && cmd_exist?("podman") && podman_running?
        return "Podman"
      end

      # 3. On Mac: known alternatives, then generic docker-socket fallback
      if OS.mac?
        if cmd_exist?("colima") && colima_running?
          return "Colima"
        end
        if cmd_exist?("podman") && podman_running?
          return "Podman"
        end
        # Unknown alternative (OrbStack, Rancher Desktop, etc.) exposing docker socket
        return "Docker" if docker_running?
      end

      # 4. On Linux: Podman fallback
      if OS.linux? && cmd_exist?("podman") && podman_running?
        return "Podman"
      end

      nil
    end

    def silent_check(cmd)
      if OS.win?
        system("#{cmd} >NUL 2>NUL")
      else
        system("#{cmd} > /dev/null 2>&1")
      end
    end

    def detect_compose_cmd
      case name
      when "Docker"
        # Prefer `docker compose` (v2 plugin), fall back to `docker-compose` (v1)
        if silent_check("docker compose version")
          "docker compose"
        elsif cmd_exist?("docker-compose")
          "docker-compose"
        end
      when "Podman"
        if cmd_exist?("podman-compose")
          "podman-compose"
        elsif silent_check("podman compose version")
          "podman compose"
        end
      when "Colima"
        # Colima uses the standard docker socket, so docker compose works
        if silent_check("docker compose version")
          "docker compose"
        elsif cmd_exist?("docker-compose")
          "docker-compose"
        end
      end
    end

    def colima_running?
      output = `colima status 2>/dev/null`.strip
      output.include?("running")
    rescue
      false
    end

    def docker_desktop_installed?
      File.exist?("/Applications/Docker.app")
    end

    # Poll ``docker info`` (or ``podman info``) until the daemon
    # answers, or the deadline expires. Called from :meth:`start!`
    # after kicking off ``colima start`` / ``open -a Docker`` because
    # both are asynchronous — the command returns before the socket
    # is reachable. Returns true on success, false on timeout; caller
    # decides whether to escalate.
    def wait_for_daemon(timeout_sec: START_TIMEOUT_SEC, poll_sec: START_POLL_INTERVAL_SEC)
      deadline = Time.now + timeout_sec
      while Time.now < deadline
        return true if docker_running? || podman_running?
        sleep poll_sec
      end
      false
    end
  end

  def initialize(pkg_name, pkg_ver, in_port, out_port, root_dir)
    raise 'Invalid pkg name/ver' unless pkg_name && pkg_ver

    @pkg_name = pkg_name
    @pkg_ver = pkg_ver
    @in_port = in_port
    @out_port = out_port
    @root_dir = root_dir
  end

  def build
    self.class.ensure!
    ex "#{runtime_cmd} build --tag #{@pkg_name}:#{@pkg_ver} #{@root_dir}"
  end

  def run
    self.class.ensure!
    ex "#{runtime_cmd} run --publish #{@in_port}:#{@out_port} --detach --name #{@pkg_name} #{@pkg_name}:#{@pkg_ver}"
  end

  def stop
    self.class.ensure!
    ex "#{runtime_cmd} stop #{@pkg_name}"
  end

  def should_be_enabled
    raise 'Should enable docker first' unless @pkg_name
  end

  private

  def runtime_cmd
    case self.class.name
    when "Docker", "Colima"
      "docker"
    when "Podman"
      "podman"
    end
  end

  def ex(cmd)
    system(cmd)
  end
end