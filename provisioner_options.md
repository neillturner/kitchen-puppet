
# Provisioner Options

key | default value | Notes
----|---------------|--------
puppet_version | "latest"| desired version, affects apt installs
puppet_platform | naively tries to determine | OS platform of server
require_puppet_repo | true | Set if using a puppet install from yum or apt repo
puppet_apt_repo | "http://apt.puppetlabs.com/puppetlabs-release-precise.deb"| apt repo
puppet_yum_repo | "https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm"| yum repo
require_puppet_omnibus | false | Set if using omnibus puppet install
puppet_omnibus_url | | omnibus puppet install location.
puppet_omnibus_remote_path | "/opt/puppet" | Server Installation location of an omnibus puppet install.
manifests_path | | puppet repo manifests directory
manifest | 'site.pp' | manifest for puppet apply to run
modules_path | | puppet repo manifests directory
files_path | | directory to place at /tmp/kitchen/files
fileserver_config_path | | file to place fileserver.conf
hiera_data_path | | puppet repo hiera data directory
hiera_data_remote_path | "/var/lib/hiera" | Hiera data directory on server
puppet_debug| false| Enable full debugging logging
puppet_verbose| false| Extra information logging
puppet_noop| false| puppet runs in a no-op or dry-run mode
update_package_repos| true| update OS repository metadata
custom_facts| Hash.new | Hash to set the puppet facts before running puppet apply
chef_bootstrap_url |"https://www.getchef.com/chef/install.sh"| the chef (needed for busser to run tests)
puppetfile_path | | Path to Puppetfile

## Configuring Provisioner Options

The provisioner can be configured globally or per suite, global settings act as defaults for all suites, you can then customise per suite, for example:

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


in this example, vagrant will download a box for ubuntu 1204 with no configuration management installed, then install the latest puppet and puppet apply against a puppet repo from the /repository/puppet_repo directory using the defailt manifest site.pp

To override a setting at the suite-level, specify the setting name under the suite:

    suites:
     - name: default
       manifest: foobar.pp

### Per-suite Structure

It can be beneficial to keep different Puppet layouts for different suites. Rather than having to specify the manifest, modules, etc for each suite, you can create the following directory structure and they will automatically be found:

    $kitchen_root/puppet/$suite_name/manifests
    $kitchen_root/puppet/$suite_name/modules
    $kitchen_root/puppet/$suite_name/hiera
    $kitchen_root/puppet/$suite_name/hiera.yaml
    $kitchen_root/puppet/$suite_name/Puppetfile
