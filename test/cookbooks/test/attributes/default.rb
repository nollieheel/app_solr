#
# Cookbook:: test
# Attribute:: default
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

default['test']['version'] = '7.7.3'

# Please modify for staging monolith environments
default['test']['set_ulimits']   = true
default['test']['solr_host']     = '127.0.0.1'
default['test']['solr_java_mem'] = '-Xms512m -Xmx512m'

default['test']['core_name'] = 'core1'
default['test']['core_src']  = {
  '7.7.3' => {
    solrconfig: 'solrconfig_7.7.3.xml',
    schema: 'schema_7.7.3.xml',
  },
  '6.6.6' => {
    solrconfig: 'solrconfig_6.6.6.xml',
    schema: 'schema_6.6.6.xml',
  },
  '5.5.5' => {
    solrconfig: 'solrconfig_5.5.5.xml',
    schema: 'schema_5.5.5.xml',
  },
}
