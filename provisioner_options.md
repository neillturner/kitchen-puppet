
# Puppet Apply Provisioner Options

key | default value | Notes
----|---------------|--------
puppet_version | "latest"| desired version, affects apt installs.
facter_version | "latest"| desired version, affects apt installs.
platform | platform_name kitchen.yml parameter | OS platform of server
hiera_version | "latest"| desired version, affects apt installs.
install_hiera | false | Installs `hiera-puppet` package. Not needed for puppet > 3.x.x
hiera_package | 'hiera-puppet' | Only used if `install_hiera` is set
require_puppet_repo | true | Set if using a puppet install from yum or apt repo
puppet_apt_repo | "http://apt.puppetlabs.com/puppetlabs-release-precise.deb"| apt repo Ubuntu12
_for Ubuntu15 change to_ | "http://apt.puppetlabs.com/puppetlabs-release-jessie.deb" |
puppet_yum_repo | "https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm"| yum repo RH/Centos6
_for RH/Centos7 change to_ | "https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm" |
require_puppet_collections | false | Set if using puppet collections install (Puppet v4)
puppet_yum_collections_repo | "http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm" | yum collections repo RH/Centos6
_for RH/Centos7 change to_ | "https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm" |
puppet_apt_collections_repo | "http://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb" | apt collections repo
_for Ubuntu15 change to_ | "http://apt.puppetlabs.com/puppetlabs-release-pc1-jessie.deb" |
puppet_coll_remote_path | "/opt/puppetlabs" | Server Installation location of a puppet collections install.
puppet_detailed_exitcodes | nil | Provide transaction information via exit codes. See `--detailed-exitcodes` section of `puppet help apply`
manifests_path | | puppet repo manifests directory
manifest | 'site.pp' | manifest for puppet apply to run
modules_path | | puppet repo manifests directory
files_path | | directory to place at /tmp/kitchen/files
fileserver_config_path | | file to place fileserver.conf
hiera_config_path | | path to hiera.yaml
hiera_data_path | | puppet repo hiera data directory
hiera_data_remote_path | "/var/lib/hiera" | Hiera data directory on server
puppet_debug| false| Enable full debugging logging on puppet run
puppet_verbose| false| Extra information logging on puppet run
puppet_noop| false| puppet runs in a no-op or dry-run mode
puppet_git_init | nil | initialize puppet from GIT repository, e.g. "git@github.com:example/puppet-repo.git"
puppet_git_pr | nil | checkout specific Pull Request from repository specified in puppet_git_init, e.g. "324"
update_package_repos| true| update OS repository metadata
custom_facts| Hash.new | Hash to set the puppet facts before running puppet apply
install_custom_facts| false | Install custom facts to yaml file at "/tmp/kitchen/facter/kitchen.rb"
facter_file | nil | yaml file of custom facter_files to be provided to the puppet-apply command
chef_bootstrap_url |"https://www.getchef.com/chef/install.sh"| the chef (needed for busser to run tests) NOTE: kitchen 1.4 only requires ruby to run busser so this is not required.
puppetfile_path | | Path to Puppetfile
puppet_apply_command | nil | Overwrite the puppet apply command. Needs "sudo -E puppet apply" as a prefix.
require_chef_for_busser | true | Install chef as currently needed by busser to run tests
resolve_with_librarian_puppet | true | Use librarian_puppet to resolve modules if a Puppetfile is found
librarian_puppet_ssl_file | nil | ssl certificate file for librarian-puppet
puppet_config_path | | path of custom puppet.conf file
puppet_environment | nil | puppet environment for running puppet apply (Must set if using Puppet v4)
remove_puppet_repo | false | remove copy of puppet repository and puppet configuration on server after running puppet
hiera_eyaml | false | use hiera-eyaml to encrypt hiera data
hiera_eyaml_key_remote_path | "/etc/puppet/secure/keys" | directory of hiera-eyaml keys on server
hiera_eyaml_key_path  | "hiera_keys" | directory of hiera-eyaml keys on workstation
hiera_deep_merge | false | install the deep_merge gem to support hiera deep merge mode
http_proxy | nil | use http proxy when installing puppet, packages and running puppet
https_proxy | nil | use https proxy when installing puppet, packages and running puppet
puppet_logdest | nil | _Array_ of log destinations. Include 'console' if wanted
custom_options | | custom options to add to puppet apply command.
custom_install_command | nil | Custom shell command to be used at install stage. Can be multiline. See examples below.
puppet_whitelist_exit_code | nil | Whitelist exit code expected from puppet run. Intended to be used together with `puppet_detailed_exitcodes`.


## Puppet Apply Configuring Provisioner Options

The provisioner can be configured globally or per suite, global settings act as defaults for all suites, you can then customise per suite, for example:

```yaml
    ---
    driver:
      name: vagrant

    provisioner:
      name: puppet_apply
      manifests_path: /repository/puppet_repo/manifests
      modules_path: /repository/puppet_repo/modules-mycompany
      hiera_data_path: /repository/puppet_repo/hieradata

    platforms:
    - name: nocm_ubuntu-12.04
      driver_plugin: vagrant
      driver_config:
        box: nocm_ubuntu-12.04
        box_url: http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box

    suites:
     - name: default
```

**NOTE:** With Test-Kitchen 1.4 you not longer need chef install to run the tests. You just need ruby installed version 1.9 or higher and also add to the .kitchen.yml file

```yaml
  verifier:
    ruby_bindir: '/usr/bin'
```
where /usr/bin is the location of the ruby command.

in this example, vagrant will download a box for ubuntu 1204 with no configuration management installed, then install the
latest puppet and puppet apply against a puppet repo from the /repository/puppet_repo directory using the defailt manifest site.pp

To override a setting at the suite-level, specify the setting name under the suite:

```yaml
    suites:
     - name: default
       provisioner:
         manifest: foobar.pp
```

#### custom_install_command example usage

* One liner
```yaml
    custom_install_command: yum install -y git
```
* Multiple lines, a.k.a embed shell script
```yaml
  custom_install_command: |
     command1
     command2
```
* Multiple lines join without new line
```yaml
  custom_install_command: >
     command1 &&
     command2
```

### Per-suite Structure

It can be beneficial to keep different Puppet layouts for different suites. Rather than having to specify the manifest, modules, etc for each suite, you can create the following directory structure and they will automatically be found:

    $kitchen_root/puppet/$suite_name/manifests
    $kitchen_root/puppet/$suite_name/modules
    $kitchen_root/puppet/$suite_name/hiera
    $kitchen_root/puppet/$suite_name/hiera.yaml
    $kitchen_root/puppet/$suite_name/Puppetfile

### Puppet Version
When specifying a puppet version, you must use this format: "3.6.2-1puppetlabs1". I have
no idea why Puppet versioned their repository with a trailing
"-1puppetlabs1", but there it is.


# Puppet Agent Provisioner Options

key | default value | Notes
----|---------------|--------
puppet_version | "latest"| desired version, affects apt installs.
facter_version | "latest"| desired version, affects apt installs.
platform | platform_name kitchen.yml parameter | OS platform of server
require_puppet_repo | true | Set if using a puppet install from yum or apt repo
puppet_apt_repo | "http://apt.puppetlabs.com/puppetlabs-release-precise.deb"| apt repo
puppet_yum_repo | "https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm"| yum repo
require_puppet_omnibus | false | Set if using omnibus puppet install
puppet_omnibus_url | | omnibus puppet install location.
puppet_omnibus_remote_path | "/opt/puppet" | Server Installation location of an omnibus puppet install.
puppet_detailed_exitcodes | nil | Provide transaction information via exit codes.
puppet_logdest | nil | Where to send messages. Choose between syslog, the console, and a log file.
puppet_masterport | nil | The port on which to contact the puppet master.
puppet_test | false | Enable the most common options used for testing.
puppet_onetime | true | Run the configuration once.
puppet_no_daemonize | true | Do not send the process into the background.
puppet_server | nil | will default to 'puppet'. Useful for interactively running when used with the --no-daemonize option.
puppet_waitforcert | '0' | Time to wait for certificate if agent does not yet have certificates
puppet_certname | nil | Set the certname (unique ID) of the client
puppet_digest | nil | Change the certificate fingerprinting digest algorithm. The default is SHA256
puppet_debug| false| Enable full debugging logging on puppet run
puppet_verbose| false| Extra information logging on puppet run
puppet_noop| false| puppet runs in a no-op or dry-run mode
update_package_repos| true| update OS repository metadata
custom_facts| Hash.new | Hash to set the puppet facts before running puppet apply
facterlib | nil | Path for dynamic fact generation, e.g. /etc/puppet/facter . See https://docs.puppetlabs.com/facter/2.2/custom_facts.html
chef_bootstrap_url |"https://www.getchef.com/chef/install.sh"| the chef (needed for busser to run tests)
puppet_agent_command | nil | Overwrite the puppet agent command. Needs "sudo -E puppet agent" as a prefix.
require_chef_for_busser | true | Install chef as currently needed by busser to run tests. NOTE: kitchen 1.4 only requires ruby to run busser so this is not required.
puppet_config_path | | path of custom puppet.conf file
http_proxy | nil | use http proxy when installing puppet and packages


NOTE: Puppet Collections Support not in puppet agent yet

## Puppet Agent Configuring Provisioner Options

The provisioner can be configured globally or per suite, global settings act as defaults for all suites, you can then customise per suite, for example:

```yaml
    ---
    driver:
      name: vagrant

    provisioner:
      name: puppet_agent
      puppet_debug: true
      puppet_verbose: true
      puppet_server:  puppetmaster-nocm-ubuntu-1204

    platforms:
    - name: nocm_ubuntu-12.04
      driver_plugin: vagrant
      driver_config:
        box: nocm_ubuntu-12.04
        box_url: http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box

    suites:
     - name: default
```

**NOTE:** With Test-Kitchen 1.4 you not longer need chef install to run the tests. You just need ruby installed version 1.9 or higher and also add to the .kitchen.yml file

```yaml
  verifier:
    ruby_bindir: '/usr/bin'
```
where /usr/bin is the location of the ruby command.

In this example, vagrant will download a box for ubuntu 1204 with no configuration management installed, then install the latest puppet and run puppet agent against a puppet master at puppetmaster-nocm-ubuntu-1204

NOTE: It is important that the server can resolve the hostname ip address of the puppetmaster, in this case puppetmaster-nocm-ubuntu-1204
and the puppetmaster must be able to resolve the hostname ip address address of the hostname of the node running puppet agent.
This can be done by settings in the /etc/hosts files before running puppet.

NOTE: For testing it is possible to set the puppetmaster to autosign the certificate of a node by created a file /etc/puppet/autosign.conf that contains an *.


To override a setting at the suite-level, specify the setting name under the suite:

```yaml
    suites:
     - name: default
       provisioner:
         manifest: foobar.pp
```

## Custom ServerSpec or Beaker Invocation

 Instead of using the busser use a custom serverspec invocation using [shell verifier](https://github.com/higanworks/kitchen-verifier-shell) to call it.
With such setup there is no dependency on busser and any other chef library.

Also you can specify you tests in a different directory structure or even call [beaker](https://github.com/puppetlabs/beaker) instead of server spec and have tests in beaker structure

Using a structure like
```yaml
verifier:
  name: shell
  remote_exec: true
  command: |
    sudo -s <<SERVERSPEC
    cd /opt/gdc/serverspec-core
    export SERVERSPEC_ENV=$EC2DATA_ENVIRONMENT
    export SERVERSPEC_BACKEND=exec
    serverspec junit=true tag=~skip_in_kitchen check:role:$EC2DATA_TYPE
    SERVERSPEC
```

where `serverspec` is a wrapper around `rake` invocation.
Use a `Rakefile` similar to one in https://github.com/vincentbernat/serverspec-example.

With such approach we can achieve flexibility of running same test suite both in test kitchen and actual, even production, instances.

Beware: kitchen-shell-verifier is not yet merged into test-kitchen upstream so using separate gem is unavoidable so far
