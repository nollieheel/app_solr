#
# Cookbook:: app_solr
# Resource:: standalone
#
# Copyright:: 2022, Earth U
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'pathname'
cb = 'app_solr'

unified_mode true

# Installation of standalone Solr 7.7.x as per this guide:
# https://solr.apache.org/guide/7_7/taking-solr-to-production.html

# Installation of standalone Solr 6.6.x as per this guide:
# https://solr.apache.org/guide/6_6/taking-solr-to-production.html

# Installation of standalone Solr 5.5.x as per this guide:
# http://archive.apache.org/dist/lucene/solr/ref-guide/apache-solr-ref-guide-5.5.pdf

# Check status of local standalone Solr:
#   curl http://localhost:8983/solr/admin/info/system?wt=json

property :version, String,
         description: 'Solr version to install. Only supports 5.x, 6.x, 7.x.',
         name_property: true

property :apt_packages, Array,
         description: 'Apt packages to install (e.g. openjdk packages). '\
                      'Default: openjdk-11 packages for Solr 7.x and '\
                      'openjdk-8 packages for Solr 6.x and below.'

property :extract_dir, String,
         description: 'Location to which the tarball will be extracted',
         default: '/opt'

property :solr_user, String,
         description: 'Name of user that runs Solr. This user is '\
                      'auto-created by the install script',
         default: 'solr'

property :set_ulimits, [true, false],
         description: 'If true, ulimits for :solr_user will be '\
                      'maximized to 65535',
         default: true

property :solr_dir, String,
         description: 'Main directory for Solr',
         default: '/var/solr'

property :force_install, [true, false],
         description: 'Set to true when upgrading Solr',
         default: false

property :solr_home, String,
         description: 'A setting in solr.in.sh',
         default: 'data'

property :solr_pid_dir, String,
         description: 'A setting in solr.in.sh',
         default: ''

property :solr_logs_dir, String,
         description: 'A setting in solr.in.sh',
         default: 'logs'

property :solr_host, String,
         description: 'A setting in solr.in.sh',
         default: '0.0.0.0'

property :solr_port, [Integer, String],
         description: 'A setting in solr.in.sh',
         default: '8983'

property :solr_java_mem, String,
         description: 'A setting in solr.in.sh',
         default: '-Xms1536m -Xmx1536m'

property :log4j_props, String,
         description: 'A setting in solr.in.sh',
         default: 'log4j2.xml'

property :other_props, Hash,
         description: 'Additional settings in solr.in.sh',
         default: {}

action_class do
  def form_solr_path(x)
    if x == ''
      new_resource.solr_dir
    else
      Pathname.new(x).absolute? ? x : "#{new_resource.solr_dir}/#{x}"
    end
  end
end

action :install do
  tmp = Chef::Config[:file_cache_path]

  # If major version is not here, it's not supported
  verprops = {
    '7' => {
      packages: %w(openjdk-11-jdk-headless openjdk-11-jre-headless),
      opts:     ' -n',
      conf_src: 'solr.in.sh_7.7.3.erb',
      action:   :start,
    },
    '6' => {
      packages: %w(openjdk-8-jdk-headless openjdk-8-jre-headless),
      opts:     ' -n',
      conf_src: 'solr.in.sh_6.6.6.erb',
      action:   :start,
    },
    '5' => {
      packages: %w(openjdk-8-jdk-headless openjdk-8-jre-headless),
      opts:     '',
      conf_src: 'solr.in.sh_5.5.5.erb',
      action:   :restart,
    },
  }
  mv            = new_resource.version.split('.')[0]
  major_version = verprops[mv]

  apt_update
  major_version[:packages].each do |p|
    package p
  end

  source_url = format(
                 'https://archive.apache.org/dist/lucene/solr/%s/solr-%s.tgz',
                 new_resource.version,
                 new_resource.version
               )
  tarball_name   = ::File.basename(source_url)
  install_script = 'bin/install_solr_service.sh'

  remote_file "#{tmp}/#{tarball_name}" do
    source source_url
  end

  tarball_basename = tarball_name.chomp(::File.extname(tarball_name))
  strip_comp       = install_script.split('/').length
  execute 'extract_solr_install_script' do
    cwd     tmp
    command "tar xzf #{tarball_name} #{tarball_basename}/#{install_script} "\
            "--strip-components=#{strip_comp}"
  end

  extracted_script = ::File.basename(install_script)
  solr_bin         = "#{new_resource.extract_dir}/solr/bin/solr"
  install_opts     = "-i #{new_resource.extract_dir} "\
                     "-d #{new_resource.solr_dir} "\
                     "-u #{new_resource.solr_user}"
  if new_resource.force_install
    install_opts << ' -f'
  end
  install_opts << major_version[:opts]
  execute 'install_solr' do
    cwd     tmp
    command "bash #{extracted_script} #{tarball_name} #{install_opts}"
    not_if  { ::File.exist?(solr_bin) && !new_resource.force_install }
  end

  if new_resource.set_ulimits
    user_ulimit new_resource.solr_user do
      filehandle_hard_limit 65535
      filehandle_soft_limit 65535
      process_hard_limit    65535
      process_soft_limit    65535
    end
  end

  template '/etc/default/solr.in.sh' do
    cookbook  cb
    source    major_version[:conf_src]
    owner     'root'
    group     new_resource.solr_user
    mode      '0640'
    variables(
      solr_home:     form_solr_path(new_resource.solr_home),
      solr_pid_dir:  form_solr_path(new_resource.solr_pid_dir),
      solr_logs_dir: form_solr_path(new_resource.solr_logs_dir),
      log4j_props:   form_solr_path(new_resource.log4j_props),
      solr_host:     new_resource.solr_host,
      solr_port:     new_resource.solr_port,
      solr_java_mem: new_resource.solr_java_mem,
      other_props:   new_resource.other_props
    )
  end

  service 'solr' do
    action major_version[:action]
  end
end
