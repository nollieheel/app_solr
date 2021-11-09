#
# Cookbook:: app_solr
# Resource:: standalone
#
# Copyright:: 2021, Earth U
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

property :version, String,
         description: 'Solr version to install (from the 7.x family)',
         name_property: true

property :apt_packages, Array,
         description: 'Apt packages to install',
         default: %w(
           openjdk-11-jdk-headless
           openjdk-11-jre-headless
         )

property :source_uri, String,
         description: 'Formatted URL string of the tarball download location. '\
                      ':version will be interpolated into this string.',
         default: 'https://archive.apache.org/dist/lucene/solr/%s/solr-%s.tgz'

property :install_script, String,
         description: 'Solr install script included in the tarball',
         default: 'bin/install_solr_service.sh'

property :extract_dir, String,
         description: 'Location to which the tarball will be extracted',
         default: '/opt'

property :solr_user, String,
         description: 'Name of user that runs Solr. This user is ' \
                      'auto-created by the install script',
         default: 'solr'

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
  def source_url
    format(new_resource.source_uri, new_resource.version, new_resource.version)
  end

  def tarball_name
    ::File.basename(source_url)
  end

  def install_script_path
    dir1 = ::File.basename(tarball_name, ::File.extname(tarball_name))
    "#{dir1}/#{new_resource.install_script}"
  end

  def install_opts
    opts = "-i #{new_resource.extract_dir} "\
           "-d #{new_resource.solr_dir} "\
           "-u #{new_resource.solr_user} "\
           '-n'

    if new_resource.force_install
      opts << ' -f'
    end

    opts
  end

  def form_solr_path(x)
    if x == ''
      new_resource.solr_dir
    else
      Pathname.new(x).absolute? ? x : "#{new_resource.solr_dir}/#{x}"
    end
  end

  def solr_props
    {
      solr_home:     form_solr_path(new_resource.solr_home),
      solr_pid_dir:  form_solr_path(new_resource.solr_pid_dir),
      solr_logs_dir: form_solr_path(new_resource.solr_logs_dir),
      log4j_props:   form_solr_path(new_resource.log4j_props),
      solr_host:     new_resource.solr_host,
      solr_port:     new_resource.solr_port,
      solr_java_mem: new_resource.solr_java_mem,
      other_props:   new_resource.other_props,
    }
  end
end

action :install do
  tmp = Chef::Config[:file_cache_path]

  apt_update
  execute 'DEBIAN_FRONTEND=noninteractive apt-get '\
          '-y -o Dpkg::Options::="--force-confnew" dist-upgrade'

  package new_resource.apt_packages

  remote_file "#{tmp}/#{tarball_name}" do
    source source_url
  end

  strip_comp = new_resource.install_script.split('/').length
  execute 'extract_solr_install_script' do
    cwd     tmp
    command "tar xzf #{tarball_name} #{install_script_path} "\
            "--strip-components=#{strip_comp}"
  end

  extracted_script = ::File.basename(new_resource.install_script)
  solr_bin         = "#{new_resource.extract_dir}/solr/bin/solr"
  execute 'install_solr' do
    cwd     tmp
    command "bash #{extracted_script} #{tarball_name} #{install_opts}"
    not_if  { ::File.exist?(solr_bin) && !new_resource.force_install }
  end

  user_ulimit new_resource.solr_user do
    filehandle_hard_limit 65535
    filehandle_soft_limit 65535
    process_hard_limit    65535
    process_soft_limit    65535
  end

  template '/etc/default/solr.in.sh' do
    cookbook  cb
    source    'solr.in.sh_7.7.3.erb'
    owner     'root'
    group     new_resource.solr_user
    mode      '0640'
    variables solr_props
  end

  service 'solr' do
    action :start
  end
end
