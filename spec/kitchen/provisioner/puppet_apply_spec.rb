# encoding: utf-8
require_relative '../../spec_helper.rb'

require 'kitchen/provisioner/puppet_apply'
require 'kitchen/transport/dummy'
require 'kitchen/verifier/dummy'
require 'kitchen/driver/dummy'

describe Kitchen::Busser do
  let(:busser) { Kitchen::Busser.new }

  it 'should return non suite dirs' do
    expect(busser.non_suite_dirs).to eq(%w(data data_bags environments nodes roles puppet))
  end
end

describe Kitchen::Provisioner::PuppetApply do
  let(:logged_output) { StringIO.new }
  let(:logger)        { Logger.new(logged_output) }
  let(:config)        { { test_base_path: '/kitchen' } }
  let(:platform)      { Kitchen::Platform.new(name: 'ubuntu-14.04') }
  let(:suite)         { Kitchen::Suite.new(name: 'suitey') }
  let(:verifier)      { Kitchen::Verifier::Dummy.new }
  let(:transport)     { Kitchen::Transport::Dummy.new }
  let(:state_file)    { double('state_file') }
  let(:state)         { Hash.new }
  let(:env)           { Hash.new }
  let(:driver) { Kitchen::Driver::Dummy.new }

  let(:provisioner_object) { Kitchen::Provisioner::PuppetApply.new(config) }

  # Create Provisioner With Config
  let(:provisioner) do
    p = provisioner_object
    instance
    p
  end

  # Create new Kitchen Instance
  let(:instance) do
    Kitchen::Instance.new(
      verifier: verifier,
      driver: driver,
      logger: logger,
      suite: suite,
      platform: platform,
      provisioner: provisioner_object,
      transport: transport,
      state_file: state_file
    )
  end

  # Test Puppet Apply Config
  describe 'config' do
    context 'defaults' do
      it 'Should have nil Puppet Version' do
        expect(provisioner[:puppet_version]).to eq(nil)
      end

      it 'Should have nil facter version' do
        expect(provisioner[:facter_version]).to eq(nil)
      end

      it 'Should have nil hiera version' do
        expect(provisioner[:hiera_version]).to eq(nil)
      end

      it 'should not include puppet collections' do
        expect(provisioner[:require_puppet_collections]).to eq(false)
      end

      it 'should set yum collections repo' do
        expect(provisioner[:puppet_yum_collections_repo]).to eq('http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm')
      end

      it 'should set apt collections repo' do
        expect(provisioner[:puppet_apt_collections_repo]).to eq('http://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb')
      end

      it 'should set puppet collections remote path' do
        expect(provisioner[:puppet_coll_remote_path]).to eq('/opt/puppetlabs')
      end

      it 'Should require Puppet Repo' do
        expect(provisioner[:require_puppet_repo]).to eq(true)
      end

      it 'Should require Chef for Busser' do
        expect(provisioner[:require_chef_for_busser]).to eq(true)
      end

      it 'Should resolve with librarian' do
        expect(provisioner[:resolve_with_librarian_puppet]).to eq(true)
      end

      it 'Should set puppet environment to nil' do
        expect(provisioner[:puppet_environment]).to eq(nil)
      end

      it 'Should not install custom facts' do
        expect(provisioner[:install_custom_facts]).to eq(false)
      end

      it 'Should set correct apt repo' do
        expect(provisioner[:puppet_apt_repo]).to eq('http://apt.puppetlabs.com/puppetlabs-release-precise.deb')
      end

      it 'Should set correct yum repo' do
        expect(provisioner[:puppet_yum_repo]).to eq('https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm')
      end

      it 'Should set correct chef bootstrap url' do
        expect(provisioner[:chef_bootstrap_url]).to eq('https://www.getchef.com/chef/install.sh')
      end

      it 'Should set nil puppet log destination' do
        expect(provisioner[:puppet_logdest]).to eq(nil)
      end

      it 'Should set nil puppet apply command' do
        expect(provisioner[:puppet_apply_command]).to eq(nil)
      end

      it 'should set git init to nil' do
        expect(provisioner[:puppet_git_init]).to eq(nil)
      end

      it 'should set git pr to nil' do
        expect(provisioner[:puppet_git_pr]).to eq(nil)
      end

      it 'Should set nil for http proxy' do
        expect(provisioner[:http_proxy]).to eq(nil)
      end

      it 'Should set sane hiera remote data path' do
        expect(provisioner[:hiera_data_remote_path]).to eq('/var/lib/hiera')
      end

      it 'Should set site.pp as default manifest' do
        expect(provisioner[:manifest]).to eq('site.pp')
      end

      it 'Should fail to find mainfests path' do
        expect(provisioner[:manifests_path]).to eq(nil)
      end

      it 'Should find files path' do
        expect(provisioner[:files_path]).to eq('files')
      end

      it 'Should fail to find hiera data path' do
        expect(provisioner[:hiera_data_path]).to eq(nil)
      end

      it 'Should fail to find puppet config path' do
        expect(provisioner[:puppet_config_path]).to eq(nil)
      end

      it 'Should fail to find hiera config path' do
        expect(provisioner[:hiera_config_path]).to eq(nil)
      end

      it 'Should fail to find fileserver config path' do
        expect(provisioner[:fileserver_config_path]).to eq(nil)
      end

      it 'Should fail to find puppetfile path' do
        expect(provisioner[:puppetfile_path]).to eq(nil)
      end

      it 'Should fail to find modulefile path' do
        expect(provisioner[:modulefile_path]).to eq(nil)
      end

      it 'Should fail to find metadata_json_path' do
        expect(provisioner[:metadata_json_path]).to eq(nil)
      end

      it 'Should fail to find manifests path' do
        expect(provisioner[:manifests_path]).to eq(nil)
      end

      it 'Should set Puppet Debug to False' do
        expect(provisioner[:puppet_debug]).to eq(false)
      end

      it 'Should set puppet verbose to false' do
        expect(provisioner[:puppet_verbose]).to eq(false)
      end

      it 'should set puppet noop to false' do
        expect(provisioner[:puppet_noop]).to eq(false)
      end

      it "should set puppet platform to ''" do
        expect(provisioner[:puppet_platform]).to eq(nil)
      end

      it 'should update package repos' do
        expect(provisioner[:update_package_repos]).to eq(true)
      end

      it 'should not remove puppet repo' do
        expect(provisioner[:remove_puppet_repo]).to eq(false)
      end

      it 'should set custom facts to empty hash' do
        expect(provisioner[:custom_facts]).to eq({})
      end

      it 'should not use detailed exit codes' do
        expect(provisioner[:puppet_detailed_exitcodes]).to eq(nil)
      end

      it 'should set facter file to nil' do
        expect(provisioner[:facter_file]).to eq(nil)
      end

      it 'should set facterlib to nil' do
        expect(provisioner[:facterlib]).to eq(nil)
      end

      it 'should not use librarian ssl file' do
        expect(provisioner[:librarian_puppet_ssl_file]).to eq(nil)
      end

      it 'should not use hiera eyaml' do
        expect(provisioner[:hiera_eyaml]).to eq(false)
      end

      it 'should set hiera eyaml remote path' do
        expect(provisioner[:hiera_eyaml_key_remote_path]).to eq('/etc/puppet/secure/keys')
      end

      it 'should not find hiera eyaml key path' do
        expect(provisioner[:hiera_eyaml_key_path]).to eq(nil)
      end

      it 'should set hiera deep merge to false' do
        expect(provisioner[:hiera_deep_merge]).to eq(false)
      end

      it 'should not install the hiera package' do
        expect(provisioner[:install_hiera]).to eq(false)
      end

      it 'should keep default hiera package name' do
        expect(provisioner[:hiera_package]).to eq('hiera-puppet')
      end
    end

    context 'non-default sets' do
      it 'requires puppet collections' do
        config[:require_puppet_collections] = true
        expect(provisioner[:require_puppet_collections]).to eq(true)
      end

      it 'sets yum collections repo' do
        config[:puppet_yum_collections_repo] = 'yum-http-address-foo'
        expect(provisioner[:puppet_yum_collections_repo]).to eq('yum-http-address-foo')
      end

      it 'sets apt collections repo' do
        config[:puppet_apt_collections_repo] = 'bar-http-address'
        expect(provisioner[:puppet_apt_collections_repo]).to eq('bar-http-address')
      end

      it 'sets puppet collections path' do
        config[:puppet_coll_remote_path] = '/foo/bar'
        expect(provisioner[:puppet_coll_remote_path]).to eq('/foo/bar')
      end

      # Test Puppet Version
      it 'Sets Puppet Version to 3.5.1' do
        config[:puppet_version] = '3.5.1'
        expect(provisioner[:puppet_version]).to eq('3.5.1')
      end

      # Test Facter Version
      it 'Sets Facter Version to 2.4.3' do
        config[:facter_version] = '2.4.3'
        expect(provisioner[:facter_version]).to eq('2.4.3')
      end

      # Test Hiera Version
      it 'Sets Hiera Version to 2.0.1' do
        config[:hiera_version] = '2.0.1'
        expect(provisioner[:hiera_version]).to eq('2.0.1')
      end

      it 'sets puppet repo to false' do
        config[:require_puppet_repo] = false
        expect(provisioner[:require_puppet_repo]).to eq(false)
      end

      it 'sets chef busser to false' do
        config[:require_chef_for_busser] = false
        expect(provisioner[:require_chef_for_busser]).to eq(false)
      end

      it 'should not resolve with librarian puppet' do
        config[:resolve_with_librarian_puppet] = false
        expect(provisioner[:resolve_with_librarian_puppet]).to eq(false)
      end

      it 'should set puppet environment' do
        config[:puppet_environment] = 'foo-bar'
        expect(provisioner[:puppet_environment]).to eq('foo-bar')
      end

      it 'should install custom facts' do
        config[:install_custom_facts] = true
        expect(provisioner[:install_custom_facts]).to eq(true)
      end

      it 'should set puppet_apt repo' do
        config[:puppet_apt_repo] = 'best-url-ever'
        expect(provisioner[:puppet_apt_repo]).to eq('best-url-ever')
      end

      it 'should set puppet_yum repo' do
        config[:puppet_yum_repo] = 'terrible-url'
        expect(provisioner[:puppet_yum_repo]).to eq('terrible-url')
      end

      it 'should set chef_url' do
        config[:chef_bootstrap_url] = 'not-puppet'
        expect(provisioner[:chef_bootstrap_url]).to eq('not-puppet')
      end

      it 'should set a puppet logdest' do
        config[:puppet_logdest] = '/var/log/puppet.log'
        expect(provisioner[:puppet_logdest]).to eq('/var/log/puppet.log')
      end

      it 'should set puppet apply command' do
        config[:puppet_apply_command] = 'puppet apply things.pp'
        expect(provisioner[:puppet_apply_command]).to eq('puppet apply things.pp')
      end

      it 'should set git init' do
        config[:puppet_git_init] = 'init'
        expect(provisioner[:puppet_git_init]).to eq('init')
      end

      it 'should set git pr' do
        config[:puppet_git_pr] = 'pr'
        expect(provisioner[:puppet_git_pr]).to eq('pr')
      end

      it 'should set http proxy' do
        config[:http_proxy] = 'best-proxy'
        expect(provisioner[:http_proxy]).to eq('best-proxy')
      end

      it 'should set https proxy' do
        config[:https_proxy] = 'better-proxy'
        expect(provisioner[:https_proxy]).to eq('better-proxy')
      end

      it 'should set hiera data path' do
        config[:hiera_data_remote_path] = '/foo/bar'
        expect(provisioner[:hiera_data_remote_path]).to eq('/foo/bar')
      end

      it 'should set a manifest' do
        config[:manifest] = 'fuck.pp'
        expect(provisioner[:manifest]).to eq('fuck.pp')
      end

      it 'should set a manifests path' do
        config[:manifests_path] = 'nope'
        expect(provisioner[:manifests_path]).to eq('nope')
      end

      it 'should set a modules path' do
        config[:modules_path] = 'mods'
        expect(provisioner[:modules_path]).to eq('mods')
      end

      it 'should set a files path' do
        config[:files_path] = 'fils'
        expect(provisioner[:files_path]).to eq('fils')
      end

      it 'should set hiera data path' do
        config[:hiera_data_path] = 'data'
        expect(provisioner[:hiera_data_path]).to eq('data')
      end

      it 'should set puppet config path' do
        config[:puppet_config_path] = 'nope.conf'
        expect(provisioner[:puppet_config_path]).to eq('nope.conf')
      end

      it 'should set hiera config path' do
        config[:hiera_config_path] = 'config.yaml'
        expect(provisioner[:hiera_config_path]).to eq('config.yaml')
      end

      it 'should should set fileserver config' do
        config[:fileserver_config_path] = 'server.conf'
        expect(provisioner[:fileserver_config_path]).to eq('server.conf')
      end

      it 'should set puppetfile path' do
        config[:puppetfile_path] = 'pfile'
        expect(provisioner[:puppetfile_path]).to eq('pfile')
      end

      it 'should set modulefile path' do
        config[:modulefile_path] = 'mfile'
        expect(provisioner[:modulefile_path]).to eq('mfile')
      end

      it 'should set metadata json path' do
        config[:metadata_json_path] = 'met.json'
        expect(provisioner[:metadata_json_path]).to eq('met.json')
      end

      it 'should set manifests path' do
        config[:manifests_path] = 'mfests'
        expect(provisioner[:manifests_path]).to eq('mfests')
      end

      it 'should set puppet debug' do
        config[:puppet_debug] = true
        expect(provisioner[:puppet_debug]).to eq(true)
      end

      it 'should set puppet verbose' do
        config[:puppet_verbose] = true
        expect(provisioner[:puppet_verbose]).to eq(true)
      end

      it 'should set puppet noop' do
        config[:puppet_noop] = true
        expect(provisioner[:puppet_noop]).to eq(true)
      end

      it 'should set puppet platform' do
        config[:puppet_platform] = 'oss'
        expect(provisioner[:puppet_platform]).to eq('oss')
      end

      it 'should not update package repos' do
        config[:update_package_repos] = false
        expect(provisioner[:update_package_repos]).to eq(false)
      end

      it 'should remove puppet repo' do
        config[:remove_puppet_repo] = true
        expect(provisioner[:remove_puppet_repo]).to eq(true)
      end

      it 'should set a custom fact' do
        config[:custom_facts] = { 'puppet' => 'yay' }
        expect(provisioner[:custom_facts]).to eq('puppet' => 'yay')
      end

      it 'should set detailed exitcodes' do
        config[:puppet_detailed_exitcodes] = true
        expect(provisioner[:puppet_detailed_exitcodes]).to eq(true)
      end

      it 'should set facter file' do
        config[:facter_file] = 'facts.yml'
        expect(provisioner[:facter_file]).to eq('facts.yml')
      end

      it 'should set librarian ssl file' do
        config[:librarian_puppet_ssl_file] = 'ssl_secure'
        expect(provisioner[:librarian_puppet_ssl_file]).to eq('ssl_secure')
      end

      it 'should set hiera eyaml' do
        config[:hiera_eyaml] = true
        expect(provisioner[:hiera_eyaml]).to eq(true)
      end

      it 'should set eyaml remote path' do
        config[:hiera_eyaml_key_remote_path] = 'foo/bar/bizz'
        expect(provisioner[:hiera_eyaml_key_remote_path]).to eq('foo/bar/bizz')
      end

      it 'should set eyaml key path' do
        config[:hiera_eyaml_key_path] = 'key/path'
        expect(provisioner[:hiera_eyaml_key_path]).to eq('key/path')
      end

      it 'should set hiera deep merge' do
        config[:hiera_deep_merge] = true
        expect(provisioner[:hiera_deep_merge]).to eq(true)
      end

      it 'should set spec files path' do
        config[:spec_files_path] = 'spec'
        expect(provisioner[:spec_files_path]).to eq('spec')
      end

      it 'should set spec files remote path' do
        config[:spec_files_remote_path] = '/etc/puppet/spec'
        expect(provisioner[:spec_files_remote_path]).to eq('/etc/puppet/spec')
      end

      it 'should set hiera package name' do
        config[:hiera_package] = 'hiera'
        expect(provisioner[:hiera_package]).to eq('hiera')
      end
    end
  end

  context 'init command' do
    it 'should clean spec_files_remote_path' do
      config[:spec_files_remote_path] = '/etc/puppet/spec'
      expect(provisioner.init_command).to match(/rm -rf.*#{config[:spec_files_remote_path]}/)
    end
  end

  context 'install command' do
    it 'should return if nil vars are set' do
      config[:require_puppet_collections] = nil
      config[:require_puppet_repo] = nil
      expect(provisioner.install_command).to be_nil
    end

    it 'runs custom shell command at install stage' do
      config[:custom_install_command] = 'echo "CUSTOM_SHELL"'
      expect(provisioner.install_command).to include('echo "CUSTOM_SHELL"')
    end

    it 'runs multiline custom shell command at install stage' do
      config[:custom_install_command] = <<CUSTOM_COMMAND
echo "string1"
echo "string2"
CUSTOM_COMMAND

      expect(provisioner.install_command).to include(%(echo "string1"\necho "string2"))
    end
  end

  context 'run command' do
    it 'exports FACTERLIB' do
      config[:facterlib] = '/etc/puppet/facter'
      expect(provisioner.run_command).to include("export FACTERLIB='/etc/puppet/facter';")
    end

    it 'exports MANIFESTDIR when not using puppet collections or environments' do
      config[:require_puppet_collections] = false
      config[:puppet_environment] = nil
      expect(provisioner.run_command).to include("export MANIFESTDIR='/tmp/kitchen/manifests';")
    end

    it 'exports FACTERLIB for facter directory if factor_file specified' do
      config[:facter_file] = 'facter/hello.rb'
      expect(provisioner.run_command).to include("export FACTERLIB='/tmp/kitchen/facter';")
    end

    it 'exports FACTERLIB for facter directory if install_custom_facts is true' do
      config[:install_custom_facts] = true
      config[:custom_facts] = { role: 'webserver' }
      expect(provisioner.run_command).to include("export FACTERLIB='/tmp/kitchen/facter';")
    end
  end
end
