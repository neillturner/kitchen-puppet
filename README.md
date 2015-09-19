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

## Requirements
You'll need a driver box without a chef installation so puppet can be installed. Puppet have one at http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box or http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-nocm.box.

For PuppetAgent a server with a puppet master is required that can resolve the hostname ip address of the server. The server must also be able to resolve the hostname ip address of the puppet master.

You can also use the PuppetApply driver with a docker container, provided the necessary box requirements to install puppet are included inside the container. The easiest way to do this is to supply Kitchen-Docker with a custom dockerfile to install the needed dependencies for puppet installation.

## Windows Workstation Install

You need to download the puppet msi and install it and run everything inside the puppet window. 

1. Download and install puppet from the windows msi file from https://downloads.puppetlabs.com/windows
  * I recommend the using the 32 bit version as not all ruby gems works with the 64 bit version.
  * Don't do a 'gem install puppet' !!!.

2. Select "Start Command Prompt with Puppet" to go to a Command Window.

3. install the Ruby DevKit:
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
