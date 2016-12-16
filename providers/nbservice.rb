def whyrun_supported?
  true
end

def cmd_jupyter
  conda_path = ::File.join(node.anaconda.install_root, node.anaconda.version)
  if node.anaconda.env
    conda_path = ::File.join(conda_path, 'envs', node.anaconda.env)
  end

  conda_path = ::File.join(conda_path, 'bin', 'jupyter')
  return conda_path
end

def is_installed?(package_name)
  `"#{cmd_conda}" list`.include?(package_name)
end

def log_opts(node)
  if node.anaconda.install_log
    "2>&1 >#{node.anaconda.install_log}"
  else
    ''
  end
end

action :create do
  r = new_resource
  # fill in any missing attributes with the defaults
  ip = r.ip || node.anaconda.notebook.ip
  port = r.port || node.anaconda.notebook.port
  owner = r.owner || node.anaconda.notebook.owner
  group = r.group || node.anaconda.notebook.group
  install_dir = r.install_dir || node.anaconda.notebook.install_dir

  directory install_dir do
    owner owner
    group group
    recursive true
  end

  ipython_dir = "#{install_dir}/.ipython"
  directory ipython_dir do
    owner owner
    group group
    recursive true
  end

  pythonpath = r.pythonpath || nil
  pythonstartup = r.pythonstartup || nil
  files_to_source = r.files_to_source || [ ]
  service_action = r.service_action || [ :enable, :start ]

  template_cookbook = r.template_cookbook || 'anaconda'
  run_template_name = r.run_template_name || 'jupyter-notebook'
  run_template_opts = r.run_template_opts || {
    :owner => owner,
    :cmd_jupyter => cmd_jupyter(),
    :notebook_dir => install_dir,
    :ipython_dir => ipython_dir,
    :ip => ip,
    :port => port,
    :pythonpath => pythonpath,
    :pythonstartup => pythonstartup,
    :files_to_source => files_to_source,
  }

  runit_service "jupyter-notebook-#{r.name}" do
    options(run_template_opts)
    default_logger true
    run_template_name run_template_name
    cookbook template_cookbook
    action service_action
  end
end
