#
# Cookbook:: app_solr
# Resource:: standalone_core
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

# Create a core in standalone Solr

# Check status of local standlone Solr core:
#   curl 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=corename'

# By default, this resource creates a core using version 7.7.3
# solrconfig.xml and schema.xml files. Custom files can be provided
# as properties.
# The cookbook also includes default solrconfig.xml and schema.xml files
# for each version: 5.5.5, 6.6.6, and 7.7.3.

property :name, String,
         description: 'Name of Solr core to create',
         name_property: true

property :extract_dir, String,
         description: 'Location of the extracted Solr installation files',
         default: '/opt'

property :solr_user, String,
         description: 'Name of Solr user',
         default: 'solr'

# Used only to provide a consistent :solr_home property
# between the app_solr_core and app_solr_standalone resources.
property :solr_dir, String,
         description: 'Main directory for Solr. '\
                      'Only used if :solr_home is relative.',
         default: '/var/solr'

property :solr_home, String,
         description: 'Location of Solr home. Can be relative to :solr_dir.',
         default: 'data'

property :use_custom_solrconfig, [true, false],
         description: 'Whether or not to use a custom solrconfig.xml. If '\
                      'true, provide values for :solrconfig_source and '\
                      ':solrconfig_cookbook.',
         default: false

property :solrconfig_source, String,
         description: 'Name of the cookbook_file source for a '\
                      'custom solrconfig.xml',
         default: 'solrconfig.xml'

property :solrconfig_cookbook, String,
         description: 'Cookbook of cookbook_file for custom solrconfig.xml',
         default: cb

property :use_custom_schema, [true, false],
         description: 'Whether or not to use a custom schema.xml. If '\
                      'true, provide values for :schema_source and '\
                      ':schema_cookbook. Useful if using the '\
                      '"ClassicIndexSchemaFactory" schemaFactory in :solrconfig ',
         default: false

property :schema_source, String,
         description: 'Name of the cookbook_file source for a '\
                      'custom schema.xml',
         default: 'schema.xml'

property :schema_cookbook, String,
         description: 'Cookbook of cookbook_file for custom schema.xml',
         default: cb

action_class do
  def form_solr_path(x)
    if x == ''
      new_resource.solr_dir
    else
      Pathname.new(x).absolute? ? x : "#{new_resource.solr_dir}/#{x}"
    end
  end
end

action :create do
  core_dir = "#{form_solr_path(new_resource.solr_home)}/#{new_resource.name}"

  solr_bin = "#{new_resource.extract_dir}/solr/bin/solr"
  execute "create_solr_core_#{new_resource.name}" do
    command "#{solr_bin} create -c #{new_resource.name}"
    user    new_resource.solr_user
    group   new_resource.solr_user
    not_if  { ::File.exist?("#{core_dir}/core.properties") }
  end

  cookbook_file "#{core_dir}/conf/solrconfig.xml" do
    source   new_resource.solrconfig_source
    cookbook new_resource.solrconfig_cookbook
    owner    new_resource.solr_user
    group    new_resource.solr_user
    mode     '0660'
    only_if  { new_resource.use_custom_solrconfig }
  end

  cookbook_file "#{core_dir}/conf/schema.xml" do
    source   new_resource.schema_source
    cookbook new_resource.schema_cookbook
    owner    new_resource.solr_user
    group    new_resource.solr_user
    mode     '0660'
    only_if  { new_resource.use_custom_schema }
  end

  service 'solr' do
    action  :restart
    only_if { new_resource.use_custom_solrconfig || new_resource.use_custom_schema }
  end
end
