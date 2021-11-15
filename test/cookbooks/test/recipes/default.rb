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

app_solr_standalone node['test']['version']

case node['test']['version']
when '7.7.3'
  app_solr_core 'core1' do
    use_custom_solrconfig true
    use_custom_schema     true
  end
when '6.6.6'
  app_solr_core 'core1' do
    use_custom_solrconfig true
    solrconfig_source     'solrconfig_6.6.6.xml'
    solrconfig_cookbook   'app_solr'
    use_custom_schema     true
    schema_source         'schema_6.6.6.xml'
    schema_cookbook       'app_solr'
  end
end
