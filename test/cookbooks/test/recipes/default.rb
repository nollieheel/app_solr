#
# Cookbook:: test
# Recipe:: default
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

# So Inspec can use node attributes
ruby_block 'save node attribs' do
  block do
    ::File.write("/tmp/kitchen_chef_node.json", node.to_json)
  end
end

app_solr_standalone node['test']['version'] do
  set_ulimits   node['test']['set_ulimits']
  solr_host     node['test']['solr_host']
  solr_java_mem node['test']['solr_java_mem']
end

app_solr_core node['test']['core_name'] do
  use_custom_solrconfig true
  solrconfig_source     node['test']['core_src'][node['test']['version']][:solrconfig]
  solrconfig_cookbook   'app_solr'

  use_custom_schema true
  schema_source     node['test']['core_src'][node['test']['version']][:schema]
  schema_cookbook   'app_solr'
end
