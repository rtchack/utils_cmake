# Use docker
class Docker
  def initialize(pkg_name, pkg_ver, in_port, out_port, root_dir)
    raise 'Invalid pkg name/ver' unless pkg_name && pkg_ver

    @pkg_name = pkg_name
    @pkg_ver = pkg_ver
    @in_port = in_port
    @out_port = out_port
    @root_dir = root_dir
  end

  def build
    should_be_enabled
    ex "docker build --tag #{@pkg_name}:#{@pkg_ver} #{@root_dir}"
  end

  def run
    should_be_enabled
    ex "docker run --publish #{@in_port}:#{@out_port} \
--detach --name #{@pkg_name} #{@pkg_name}:#{@pkg_ver}"
  end

  def stop
    should_be_enabled
    ex "docker stop #{@pkg_name}"
  end

  def should_be_enabled
    raise 'Should enable docker first' unless @pkg_name
  end
end
