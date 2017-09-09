# Kitchen Puppet

[![Gem Version](https://badge.fury.io/rb/kitchen-puppet.svg)](http://badge.fury.io/rb/kitchen-puppet)
[![Gem Downloads](http://ruby-gem-downloads-badge.herokuapp.com/kitchen-puppet?type=total&color=brightgreen)](https://rubygems.org/gems/kitchen-puppet)
[![Build Status](https://travis-ci.org/neillturner/kitchen-puppet.png)](https://travis-ci.org/neillturner/kitchen-puppet)

# kitchen-puppet
A Test Kitchen Provisioner for Puppet

The providers supports both puppet apply and puppet agent clients

The PuppetApply provider works by passing the puppet repository based on attributes in .kitchen.yml & calling puppet apply.

The PuppetAgent provider works by passing the puppetmaster and other attributes in .kitchen.yml & calling puppet agent.


This provider has been tested against the Ubuntu 1204 and Centos 6.5 boxes running in vagrant/virtualbox as well as various docker.

## Resources
* http://ehaselwanter.com/en/blog/2014/05/08/using-test-kitchen-with-puppet
* http://www.slideshare.net/MartinEtmajer/testdriven-infrastructure-with-puppet-test-kitchen-serverspec-and-rspec
* http://www.slideshare.net/YuryTsarev/containercon-test-driven-infrastructure
* http://events.linuxfoundation.org/sites/events/files/slides/ContainerCon%20-%20Test%20Driven%20Infrastructure_0.pdf
* https://www.cedric-meury.ch/2016/10/test-driven-infrastructure-with-puppet-docker-test-kitchen-and-serverspec-yury-tsarev-gooddata
* https://docs.puppet.com/puppet/latest/puppet_platform.html

## Install

1. install the latest Ruby on your workstations (for windows see https://rubyinstaller.org/downloads/)

2. From a Command prompt:
  * gem install librarian-puppet
  * gem install test-kitchen  (Add parameter -v 1.16.0 if using ruby version less than 2.3) 
  * gem install kitchen-puppet

## Requirements
It is recommended to have a metadata.json file of your puppet module. It is used by kitchen-puppet to configure the module path.
The puppet docs describe (https://docs.puppetlabs.com/puppet/latest/reference/modules_publishing.html#write-a-metadatajson-file) how to create one.

You'll need a driver box without a chef installation so puppet can be installed. Puppet have one at http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box or http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-nocm.box.

For PuppetAgent a server with a puppet master is required that can resolve the hostname ip address of the server. The server must also be able to resolve the hostname ip address of the puppet master.

You can also use the PuppetApply driver with a docker container, provided the necessary box requirements to install puppet are included inside the container. The easiest way to do this is to supply Kitchen-Docker with a custom dockerfile to install the needed dependencies for puppet installation.

## Windows Support

There is windows/winrm support, currently not all functionality is supported.
  * `require_chef_for_busser: false` (it is possible to call rspec over winrm to run the tests)
  * `resolve_with_librarian_puppet: false` (librarian-puppet is not working on windows server)

Sample Puppet Repositories
  * A sample hello world example puppet repository: https://github.com/neillturner/puppet_windows_repo
  * A sample hello world example puppet repository for vagrant: https://github.com/neillturner/puppet_vagrant_windows_repo
  * A more extensive sample installing virtualbox on windows: https://github.com/red-gate/puppet-virtualbox_windows

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
`spec/acceptance` directory in the puppet repository and the `spec_helper.rb` under the `spec` directory which is more logical.

For examples see:
* https://gitlab.com/joshbeard/puppet-module-test
* https://github.com/puppetlabs/puppetlabs-mysql/tree/master/spec

To implement this with test-kitchen setup the puppet repository with:

* the spec files with the spec/acceptance directory.

* the spec_helper in the spec folder.

* install kitchen-verifier-serverspec on your workstation i.e. 'gem install kitchen-verifier-serverspec'

See examples:
* [https://github.com/neillturner/puppet_vagrant_repo](https://github.com/neillturner/puppet_vagrant_repo)

* [https://github.com/neillturner/puppet_repo](https://github.com/neillturner/puppet_repo)

```
.
+-- spec
¦   +-- acceptance
¦   ¦   +-- mariadb_spec.rb
¦   ¦   +-- nginx_spec.rb
¦   ¦
    +-- spec_helper.rb

```

In the root directory for your puppet repository create a `.kitchen.yml` with

* a verifier of 'serverspec'
* a pattern parameter with the spec tests to run

```yaml
verifier:
  name: serverspec

suites:
  - name: base
    verifier:
      patterns:
      - modules/mycompany_base/spec/acceptance/base_spec.rb
```

See [kitchen-verifier-serverspec](https://github.com/neillturner/kitchen-verifier-serverspec)

## hiera_writer_files option

Allows creation of arbitrary YAML files in the target instance's `hieradata/`
dir in test-kitchen configuration (eg `kitchen.yml`). Like setting chef
attributes in `kitchen.yml`, except for Hiera YAML files.

set `hiera_writer_files` in `kitchen.yml`

```
---
driver:
  name: vagrant

provisioner:
  name: puppet_apply
  manifests_path: /repository/puppet_repo/manifests
  modules_path: /repository/puppet_repo/modules-mycompany
  hiera_data_path: /repository/puppet_repo/hieradata
  hiera_writer_files:
    - datacenter/vagrant.yaml:
        logstash_servers: []
        hosts:
          10.1.2.3:
          - puppet
          - puppetdb

platforms:
- name: nocm_ubuntu-12.04
  driver_plugin: vagrant
  driver_config:
    box: nocm_ubuntu-12.04
    box_url: http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box

suites:
 - name: default
```

The above configuration will result in the creation of a file on the guest named
`${hieradata}/datacenter/vagrant.yaml` containing:

```
---
logstash_servers: []
  hosts:
    10.1.2.3:
    - puppet
    - puppetdb
```

It will overwrite any existing Hiera YAML files with the same name (on the
guest), not merge.

## Provisioner Options
Please see the Provisioner Options (https://github.com/neillturner/kitchen-puppet/blob/master/provisioner_options.md).

## Contributing
To contribute to the repository, please follow the Fork / PR model:

1. Fork The Repository
2. Work on epic changes
3. Write tests for your changes, see [TESTING](TESTING.md)
4. Update Documentation
5. Commit
6. Push
7. Create PR
8. Profit(?)
