#
# Created by xing
#

require_relative 'os'
require_relative 'string'

class Docker
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
