
# Puppet Apply Provisioner Options

key | default value | Notes
----|---------------|--------
puppet_version | "latest"| desired version, affects apt installs.
facter_version | "latest"| desired version, affects apt installs.
hiera_version | "latest"| desired version, affects apt installs.
puppet_platform | naively tries to determine | OS platform of server
require_puppet_repo | true | Set if using a puppet install from yum or apt repo
puppet_apt_repo | "http://apt.puppetlabs.com/puppetlabs-release-precise.deb"| apt repo
puppet_yum_repo | "https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm"| yum repo
require_puppet_collections | false | Set if using puppet collections install (Puppet v4)
puppet_yum_collections_repo | "http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm" | yum collections repo
puppet_apt_collections_repo | "http://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb" | apt collections repo
puppet_coll_remote_path | "/opt/puppetlabs" | Server Installation location of a puppet collections install.
puppet_detailed_exitcodes | nil | Provide transaction information via exit codes.
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
install_custom_facts| false | Install custom facts to yaml file at "/tmp/kitchen/facter/kitchen.yaml"
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
facter_file | nil | yaml file of custom facter_files to be provided to the puppet-apply command
http_proxy | nil | use http proxy when installing puppet, packages and running puppet
https_proxy | nil | use https proxy when installing puppet, packages and running puppet
puppet_logdest | nil | _Array_ of log destinations. Include 'console' if wanted


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
puppet_platform | naively tries to determine | OS platform of server
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
