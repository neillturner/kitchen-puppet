
# Provisioner Options

key | default value | Notes
----|---------------|--------
puppet_version | "latest"| desired version, affects apt installs
puppet_platform | naively tries to determine | OS platform of server 
puppet_apt_repo | "http://apt.puppetlabs.com/puppetlabs-release-precise.deb"| apt repo
puppet_yum_repo | "https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm"| yum repo
manifests_path | | puppet repo manifests directory
manifest | 'site.pp' | manifest for puppet apply to run
modules_path | | puppet repo manifests directory
hiera_data_path | | puppet repo manifests directory
puppet_debug| false| Enable full debugging logging
puppet_verbose| false| Extra information logging
puppet_noop| false| puppet runs in a no-op or dry-run mode
update_packages| true| update OS packages before installing puppet
custom_facts| Hash.new | Hash to set the puppet facts before running puppet apply
chef_bootstrap_url |"https://www.getchef.com/chef/install.sh"| the chef (needed for busser to run tests)

##Configuring Provisioner Options
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


in this example, vagrant will download a box for ubuntu 1204 with no configuration management installed, then install the latest puppet and puppet apply against the puppet repo from the /repository/puppet_repo directory using the defailt manifest site.pp
