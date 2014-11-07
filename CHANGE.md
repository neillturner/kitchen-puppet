v0.0.18
* Add http_proxy support 

v0.0.17
* Syntax fix with file resource
* Update and Fix all syntax errors
* Adds facter_file config parameter to puppet_apply
* Regex fix when testing module in kitchen_root

v0.0.16
* Add hiera-eyaml support for encrypted hiera data
* improve removed repo option to remove puppet configuration
* Add option to configured SSL certificate when calling librarian-puppet

v0.0.15
* Add Puppet Agent support 

v0.0.14
* Add Puppet environment option 

v0.0.13
* Resolve with librarian-puppet moved back to *before* copying modules directory as librarian-puppet was clobbering the copied modules.
  Note: you should adopt a naming convention where the modules in the modules directory are prefix with a company prefix so they don't 
  conflict with the librarian puppet module names. ie mycompany-module.

* Added require_chef_for_busser provisioner option that defaults to true. Currently chef is required by the busser to run tests. 
  If you just want to setup a server with puppet and converge it and don't want chef install then set to false. 

* Added resolve_with_librarian provisioner option that defaults to true. This will cause librarian_puppet to resolve modules if a Puppetfile is found.   

* Allow custom puppet apply command

* Fix Dependency Issue with Puppet Version

* Enable usage of custom puppet.conf 

* Update documentation with hiera_config_path

* Detect Oracle Linux

v0.0.12 June 4, 2014
* Resolve with librarian-puppet *after* copying modules directory in order to avoid errors copying modules after having done
 `librarian-puppet install` on the host.

v0.0.11 May 25, 2014
* enable the per suite manifest

v0.0.10 May 19, 2014
* auto detect if this is meant to be a module and copy it as just another module

v0.0.9 May 14, 2014
* Provide platform flexibility in installing puppet/chef
* Configure Puppet's fileserver config for local delivery
* Define puppet_gem_version
* remove destination before copying modules

v0.0.8 May 12, 2014
* initial version