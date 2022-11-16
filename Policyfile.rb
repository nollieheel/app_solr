# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile/

# A name that describes what the system you're building with Chef does.
name 'app_solr'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'test::default'
named_run_list :v7, 'test::default'
named_run_list :v6, 'test::default'
named_run_list :v5, 'test::default'

# Specify a custom source for a single cookbook:
cookbook 'app_solr', path: '.'
cookbook 'test', path: 'test/cookbooks/test'
