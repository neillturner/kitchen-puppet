# Kitchen Puppet

[![Gem Version](https://badge.fury.io/rb/kitchen-puppet.svg)](http://badge.fury.io/rb/kitchen-puppet)
[![Gem Downloads](http://ruby-gem-downloads-badge.herokuapp.com/kitchen-puppet?type=total&color=brightgreen)](https://rubygems.org/gems/kitchen-puppet)
[![Build Status](https://travis-ci.org/neillturner/kitchen-puppet.png)](https://travis-ci.org/neillturner/kitchen-puppet)

# kitchen-puppet
A Test Kitchen Provisioner for Puppet

The providers supports both puppet apply and puppet agent clients

The PuppetApply provider works by passing the puppet repository based on attributes in .kitchen.yml & calling puppet apply.

The PuppetAgent provider works by passing the puppetmaster and other attributes in .kitchen.yml & calling puppet agent.


This provider has been tested against the Ubuntu 1204 and Centos 6.5 boxes running in vagrant/virtualbox as well as various docker .

## Windows Workstation Install
You need to download the puppet msi and install it and run everything inside the puppet window.

1. Download and install puppet from the windows msi file from https://downloads.puppetlabs.com/windows
  * I recommend the using the 32 bit version as not all ruby gems works with the 64 bit version.
  * Don't do a 'gem install puppet' !!!.

2. Select "Start Command Prompt with Puppet" to go to a Command Window.

3. Install the Ruby DevKit:
   * Download and install devkit from http://rubyinstaller.org/downloads
     * (Use a 32 or 64 bit version that matches version of the ruby install)
   * In the devkit directory run “ruby dk.rb init”.
   * Edit the config.yml generated and add the the path of the ruby install for puppet
     * (it will be <install dir of puppet>/sys/ruby).
   * Run “ruby dk.rb install” to bind it to the puppet ruby installation.

4. From a Command prompt:
  * gem install librarian-puppet
  * gem install test-kitchen
  * gem install kitchen-puppet

## Mac-OSX Workstation Install

1. Download and install the mac packages from https://downloads.puppetlabs.com/mac/
  * The most recent Facter package (facter-<VERSION>.dmg)
  * The most recent Hiera package (hiera-<VERSION>.dmg)
  * The most recent Puppet package (puppet-<VERSION>.dmg)
  * See [How to Install Software from DMG Files on a Mac](http://www.ofzenandcomputing.com/how-to-install-dmg-files-mac/) for details.

2. From a Command prompt:
  * gem install librarian-puppet
  * gem install test-kitchen
  * gem install kitchen-puppet

## Requirements
It is recommended to have a metadata.json file of your puppet module. It is used by kitchen-puppet to configure the module path.
The puppet docs describe (https://docs.puppetlabs.com/puppet/latest/reference/modules_publishing.html#write-a-metadatajson-file) how to create one.

You'll need a driver box without a chef installation so puppet can be installed. Puppet have one at http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box or http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-nocm.box.

For PuppetAgent a server with a puppet master is required that can resolve the hostname ip address of the server. The server must also be able to resolve the hostname ip address of the puppet master.

You can also use the PuppetApply driver with a docker container, provided the necessary box requirements to install puppet are included inside the container. The easiest way to do this is to supply Kitchen-Docker with a custom dockerfile to install the needed dependencies for puppet installation.

## Test-Kitchen Serverspec

To run the verify step with the test-kitchen serverspec setup your puppet repository as follows:

In the root directory for your puppet repository:

Create a `.kitchen.yml`, much like one the described above:

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

Then for serverspec:

```bash
  mkdir -p test/integration/default/serverspec/localhost
  echo "require 'serverspec'" >> test/integration/default/serverspec/spec_helper.rb
  echo "set :backend, :exec" >> test/integration/default/serverspec/spec_helper.rb
```

Create your serverspec tests in `test/integration/default/serverspec/localhost/xxxxxx_spec.rb`:

```ruby
  require 'spec_helper'

  if os[:family] == 'ubuntu'
        describe '/etc/lsb-release' do
          it "exists" do
              expect(file('/etc/lsb-release')).to be_file
          end
        end
  end

  if os[:family] == 'redhat'
    describe '/etc/redhat-release' do
      it "exists" do
          expect(file('/etc/redhat-release')).to be_file
      end
    end
  end
```

## Test-Kitchen Beaker

test-kitchen normally uses tests setup in `test/integration/....` directory. Beaker format puts the tests with the
`spec/acceptance directory` in the puppet repository and the `spec_helper_acceptance.rb` under the `spec` directory.

For eaxmples see:
[https://gitlab.com/joshbeard/puppet-module-test]
[https://github.com/puppetlabs/puppetlabs-mysql/tree/master/spec]

To implement this with test-kitchen setup the puppet repository with:

* the spec files with the spec/acceptance directory.

* the spec_helper_acceptance in the spec folder.

* a dummy `test/integration/<suite>/beaker/localhost/<suite>_spec.rb` containing just a dummy comment.

See example [https://github.com/neillturner/puppet_repo](https://github.com/neillturner/puppet_repo)

```
.
+-- spec
¦   +-- acceptance
¦   ¦   +-- mariadb_spec.rb
¦   ¦   +-- nginx_spec.rb
¦   ¦
¦   +-- spec_helper_acceptance.rb
+-- test
    +-- integration
        +-- default      # name of test-kitchen suite
            +-- beaker
                +-- localhost
                    +-- default_spec.rb   # <suite>_spec.rb
```

In the root directory for your puppet repository create a `.kitchen.yml`, the same as for test-kitchen serverspec above.

When test-kitchen runs the verify step will
* detect the dummy `/test/integration/<suite>/beaker` directory
* install the busser-beaker plugin instead of the normal busser-serverspec plugin
* serverspec will be called using the beaker conventions.

See [busser-beaker](https://github.com/neillturner/busser-beaker)


## Provisioner Options
Please see the Provisioner Options (https://github.com/neillturner/kitchen-puppet/blob/master/provisioner_options.md).

## Contributing
To contriubute to the repository, please follow the Fork / PR model:

1. Fork The Repository
2. Work on epic changes
3. Write tests for your changes
4. Update Documentation
5. Commit
6. Push
7. Create PR
8. Profit(?)
