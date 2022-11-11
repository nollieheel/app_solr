# Chef InSpec test for recipe app_solr::default

# The Chef InSpec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec/resources/

# Accessing node attributes
p    = json('/tmp/kitchen_chef_node.json').params
vdef = p['default'].has_key?('test') ? p['default']['test'] : {}
vnor = p['normal'].has_key?('test') ? p['normal']['test'] : {}
vove = p['override'].has_key?('test') ? p['override']['test'] : {}
v    = (vdef.merge(vnor)).merge(vove)

# Tests for resource: app_solr_standalone

describe systemd_service('solr.service') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/etc/default/solr.in.sh') do
  its('content') { should match /SOLR_HOST="#{v['solr_host']}"/ }
  its('content') { should match /SOLR_JAVA_MEM="#{v['solr_java_mem']}"/ }
  its('content') { should match %r{SOLR_HOME="/var/solr/data"} }
  its('content') { should match %r{SOLR_PID_DIR="/var/solr"} }
  its('content') { should match %r{SOLR_LOGS_DIR="/var/solr/logs"} }
  its('content') { should match %r{LOG4J_PROPS="/var/solr/log4j2\.xml"} }
end

describe port(8983) do
  it { should be_listening }
end

describe http('http://localhost:8983/solr/admin/info/system?wt=json') do
  its('status') { should eq 200 }
  its('body') { should match /"solr-spec-version":"#{v['version']}"/ }
end

if v['set_ulimits']
  describe file('/etc/security/limits.d/solr_limits.conf') do
    its('content') { should match /solr soft nofile 65535/ }
    its('content') { should match /solr hard nofile 65535/ }
    its('content') { should match /solr soft nproc 65535/ }
    its('content') { should match /solr hard nproc 65535/ }
  end
end

# Tests for resource: app_solr_core

describe http("http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=#{v['core_name']}") do
  its('status') { should eq 200 }
  its('body') { should match %r{"instanceDir":"/var/solr/data/#{v['core_name']}"} }
  its('body') { should match %r{"dataDir":"/var/solr/data/#{v['core_name']}/data/"} }
end
