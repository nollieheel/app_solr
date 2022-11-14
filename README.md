# app_solr

A cookbook that install Solr with basic settings. Only tested with Solr versions 5.x to 7.x.

## Supported Platforms

LTS version of Ubuntu >= 20.04

## Resources

### app_solr_standalone

Install a local standalone (not cluster) Solr.

```ruby
app_solr_standalone '7.7.3' do
  solr_java_mem '-Xms512m -Xmx512m'
end
```

#### Actions

- `install` - Install Solr locally in standalone mode

#### Properties

- `version` - Solr version to install. Default to name of resource.
- `apt_packages` - OS packages to install. Default: _openjdk-11_ packages for Solr 7.x and _openjdk-8_ packages for Solr 6.x and below.
- `extract_dir` - Path to which tarball will be extracted. Default: `/opt`.
- `solr_user` - User to run Solr. Will be auto-created by installer. Default: `solr`.
- `set_ulimits` - If true, :solr_user ulimits will be maximized to 65535. Default: true.
- `solr_dir` - Main Solr directory. Default: `/var/solr`.
- `force_install` - Set to true when upgrading Solr. Default: false.

Settings that will be included directly into `/etc/default/solr.in.sh`:
- `solr_home`
- `solr_pid_dir`
- `solr_logs_dir`
- `solr_host`
- `solr_port`
- `solr_java_mem`
- `log4j_props`

### app_solr_core

Create a Solr core.

```ruby
app_solr_core 'myapp1' do
  use_custom_solrconfig true
  solrconfig_source     'solrconfig.xml'
  solrconfig_cookbook   'mycookbook'
end
```

#### Actions

- `create` - Create the core

#### Properties

- `name` - Name of core. Defaults to name of resource.
- `extract_dir` - Path to which Solr installer tarball was extracted. Default: `/opt`.
- `solr_user` - User that runs Solr. Default: `solr`.
- `solr_home` - Location of Solr home relative to :solr_dir. Default: `data`.
- `use_custom_solrconfig` - Set to true in order to use custom `solrconfig.xml` file. Default: false.
- `solrconfig_source` - cookbook_file source for custom `solrconfig.xml` file.
- `solrconfig_cookbook` - cookbook_file cookbook for custom `solrconfig.xml` file.
- `use_custom_schema` - Set to true when using ClassicIndexSchemaFactory to use custom `schema.xml` file.
- `schema_source` - cookbook_file source for custom `schema.xml` file.
- `schema_cookbook` - cookbook_file cookbook for custom `schema.xml` file.

## License and Authors

Author:: Earth U (<iskitingbords@gmail.com>)
