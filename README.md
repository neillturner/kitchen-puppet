# Kitchen Puppet

[![Gem Version](https://badge.fury.io/rb/kitchen-puppet.svg)](http://badge.fury.io/rb/kitchen-puppet)

# kitchen-puppet
A Test Kitchen Provisioner for Puppet

The providers supports both puppet apply and puppet agent clients

The PuppetApply provider works by passing the puppet repository based on attributes in .kitchen.yml & calling puppet apply.

The PuppetAgent provider works by passing the puppetmaster and other attributes in .kitchen.yml & calling puppet agent.


This provider has been tested against the Ubuntu 1204 and Centos 6.5 boxes running in vagrant/virtualbox.

## Requirements
You'll need a driver box without a chef installation so puppet can be installed. Puppet have one at http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box or http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-nocm.box.

For PuppetAgent a server with a puppet master is required that can resolve the hostname ip address of the server. The server must also be able to resolve the hostname ip address of the puppet master.  

## Installation & Setup
You'll need the test-kitchen & kitchen-puppet gem's installed in your system, along with kitchen-vagrant or some ther suitable driver for test-kitchen. 

Please see the Provisioner Options (https://github.com/neillturner/kitchen-puppet/blob/master/provisioner_options.md).
