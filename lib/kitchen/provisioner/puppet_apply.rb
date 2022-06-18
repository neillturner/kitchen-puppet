# -*- encoding: utf-8 -*-

#
# Author:: Chris Lundquist (<chris.lundquist@github.com>) Neill Turner (<neillwturner@gmail.com>)
#
# Copyright (C) 2013,2014 Chris Lundquist, Neill Turner
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# See https://github.com/neillturner/kitchen-puppet/blob/master/provisioner_options.md
# for documentation configuration parameters with puppet_apply provisioner.
#

require 'uri'
require 'json'
require 'kitchen'

module Kitchen
  class Busser
    def non_suite_dirs
      %w[data data_bags environments nodes roles puppet]
    end
  end

  module Configurable
    def platform_name
      instance.platform.name
    end
  end

  module Provisioner
    #
    # Puppet Apply provisioner.
    #
    class PuppetApply < Base
      attr_accessor :tmp_dir

      default_config :require_puppet_collections, true
      default_config :puppet_yum_collections_repo, 'https://yum.puppetlabs.com/puppet5/puppet5-release-el-6.noarch.rpm'
      default_config :puppet_apt_collections_repo, 'http://apt.puppetlabs.com/puppet5-release-wheezy.deb'
      default_config :puppet_coll_remote_path, '/opt/puppetlabs'
      default_config :puppet_version, nil
      default_config :facter_version, nil
      default_config :hiera_version, nil
      default_config :install_hiera, false
      default_config :hiera_package, 'hiera-puppet'
      default_config :hiera_writer_files, nil
      default_config :require_puppet_repo, true
      default_config :require_chef_for_busser, true
      default_config :resolve_with_librarian_puppet, true
      default_config :resolve_with_r10k, false
      default_config :puppet_environment, nil
      default_config :puppet_environment_config_path do |provisioner|
        provisioner.calculate_path('environment.conf')
      end
      default_config :puppet_environment_remote_modules_path, 'modules'
      default_config :puppet_environment_remote_manifests_path, 'manifests'
      default_config :puppet_environment_remote_hieradata_path, 'hieradata'
      default_config :puppet_environment_hiera_config_path do |provisioner|
        provisioner.calculate_path('hiera.yaml', :file)
      end
      default_config :puppet_apt_repo, 'http://apt.puppetlabs.com/puppetlabs-release-precise.deb'
      default_config :puppet_yum_repo, 'https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm'
      default_config :chef_bootstrap_url, 'https://www.chef.io/chef/install.sh'
      default_config :puppet_logdest, nil
      default_config :custom_install_command, nil
      default_config :custom_pre_install_command, nil
      default_config :custom_pre_apply_command, nil
      default_config :custom_post_apply_command, nil
      default_config :puppet_whitelist_exit_code, nil
      default_config :require_puppet_omnibus, false
      default_config :puppet_omnibus_url, 'https://raw.githubusercontent.com/petems/puppet-install-shell/master/install_puppet_6_agent.sh'
      default_config :puppet_enc, nil
      default_config :ignore_spec_fixtures, false

      default_config :puppet_apply_command, nil

      default_config :puppet_git_init, nil
      default_config :puppet_git_pr, nil

      default_config :http_proxy, nil
      default_config :https_proxy, nil
      default_config :no_proxy, nil

      default_config :ignored_paths_from_root, ['spec']
      default_config :hiera_data_remote_path, nil
      default_config :manifest, ''
      default_config :puppet_binary, 'puppet'

      default_config :manifests_path do |provisioner|
        provisioner.calculate_path('manifests') ||
          raise('No manifests_path detected. Please specify one in .kitchen.yml')
      end

      default_config :modules_path do |provisioner|
        modules_path = provisioner.calculate_path('modules')
        if modules_path.nil? && provisioner.calculate_path('Puppetfile', :file).nil?
          raise('No modules_path detected. Please specify one in .kitchen.yml')
        end
        modules_path
      end

      default_config :files_path do |provisioner|
        provisioner.calculate_path('files') || 'files'
      end

      default_config :hiera_data_path do |provisioner|
        provisioner.calculate_path('hiera')
      end

      default_config :puppet_config_path do |provisioner|
        provisioner.calculate_path('puppet.conf', :file)
      end

      default_config :hiera_config_path do |provisioner|
        provisioner.calculate_path('hiera.global.yaml', :file) ||
        provisioner.calculate_path('hiera.yaml', :file)
      end

      default_config :fileserver_config_path do |provisioner|
        provisioner.calculate_path('fileserver.conf', :file)
      end
      default_config :puppetfile_path do |provisioner|
        provisioner.calculate_path('Puppetfile', :file)
      end

      default_config :modulefile_path do |provisioner|
        provisioner.calculate_path('Modulefile', :file)
      end

      default_config :metadata_json_path do |provisioner|
        provisioner.calculate_path('metadata.json', :file)
      end

      default_config :manifests_path do |provisioner|
        provisioner.calculate_path('manifests', :directory)
      end

      default_config :spec_files_path do |provisioner|
        provisioner.calculate_path('spec', :directory)
      end

      default_config :spec_files_remote_path, '/etc/puppet/spec'

      default_config :puppet_debug, false
      default_config :puppet_verbose, false
      default_config :puppet_noop, false
      default_config :puppet_show_diff, false
      default_config :puppet_future_parser, false
      default_config :platform, &:platform_name
      default_config :update_package_repos, true
      default_config :remove_puppet_repo, false
      default_config :install_custom_facts, false
      default_config :custom_facts, {}
      default_config :facterlib, nil
      default_config :puppet_detailed_exitcodes, nil
      default_config :facter_file, nil
      default_config :librarian_puppet_ssl_file, nil
      default_config :r10k_ssl_file, nil

      default_config :hiera_eyaml, false
      default_config :hiera_eyaml_key_remote_path, '/etc/puppet/secure/keys'
      default_config :puppet_environmentpath_remote_path, nil

      default_config :hiera_eyaml_gpg, false
      default_config :hiera_eyaml_gpg_recipients, false
      default_config :hiera_eyaml_gpg_secring, false
      default_config :hiera_eyaml_gpg_pubring, false
      default_config :hiera_eyaml_gpg_remote_path, '/home/vagrant/.gnupg'

      default_config :hiera_eyaml_key_path do |provisioner|
        provisioner.calculate_path('hiera_keys')
      end

      default_config :hiera_deep_merge, false
      default_config :puppet_no_sudo, false

      def calculate_path(path, type = :directory)
        base = config[:test_base_path]
        candidates = []
        candidates << File.join(base, instance.suite.name, 'puppet', path)
        candidates << File.join(base, instance.suite.name, path)
        candidates << File.join(base, path)
        candidates << File.join(Dir.pwd, path)

        candidates.find do |c|
          type == :directory ? File.directory?(c) : File.file?(c)
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def install_command
        return unless config[:require_puppet_collections] || config[:require_puppet_repo] || config[:require_puppet_omnibus]
        if config[:require_puppet_omnibus]
          install_omnibus_command
        elsif config[:require_puppet_collections]
          install_command_collections
        else
          case puppet_platform
          when 'debian', 'ubuntu'
            info("Installing puppet on #{config[:platform]}")
            # need to add a CR to avoid trouble with proxy settings concatenation
            <<-INSTALL

              #{custom_pre_install_command}
              if [ ! $(which puppet) ]; then
                #{sudo('apt-get')} -y install wget
                #{sudo('apt-get')} -y install apt-transport-https
                #{sudo('wget')} #{wget_proxy_parm} #{puppet_apt_repo}
                #{sudo('dpkg')} -i #{puppet_apt_repo_file}
                #{update_packages_debian_cmd}
                #{sudo_env('apt-get')} -y install facter#{facter_debian_version}
                #{sudo_env('apt-get')} -y install puppet-common#{puppet_debian_version}
                #{sudo_env('apt-get')} -y install puppet#{puppet_debian_version}
                #{install_hiera}
              fi
              #{install_eyaml}
              #{install_eyaml_gpg}
              #{install_deep_merge}
              #{install_busser}
              #{custom_install_command}
            INSTALL
          when 'redhat', 'centos', 'fedora', 'oracle', 'amazon'
            info("Installing puppet from yum on #{puppet_platform}")
            # need to add a CR to avoid trouble with proxy settings concatenation
            <<-INSTALL

              #{custom_pre_install_command}
              if [ ! $(which puppet) ]; then
                #{install_puppet_yum_repo}
              fi
              #{install_eyaml}
              #{install_eyaml_gpg}
              #{install_deep_merge}
              #{install_busser}
              #{custom_install_command}
            INSTALL
          when /^windows.*/
            info("Installing puppet on #{puppet_platform}")
            info('Powershell is not recognised by core test-kitchen assuming it is present') unless powershell_shell?
            <<-INSTALL
              #{custom_pre_install_command}
              if(Get-Command puppet -ErrorAction 0) { return; }
              $architecture = if( [Environment]::Is64BitOperatingSystem ) { 'x64' } else { 'x86' }
              if( '#{puppet_windows_version}' -eq 'latest' ) {
                  $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet-agent-${architecture}-latest.msi"
              } elseif( '#{puppet_windows_version}' -match '(\\d)\\.' ) {
                  $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet$($Matches[1])/puppet-agent-#{puppet_windows_version}-${architecture}.msi"
              } else {
                  $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet-#{puppet_windows_version}${architecture}.msi"
              }
              Invoke-WebRequest $MsiUrl -UseBasicParsing -OutFile "C:/puppet.msi" #{posh_proxy_parm}
              $process = Start-Process -FilePath msiexec.exe -Wait -PassThru -ArgumentList '/qn', '/norestart', '/i', 'C:\\puppet.msi'
              if ($process.ExitCode -ne 0) {
                  Write-Host "Installer failed."
                  Exit 1
              }
              #{install_busser}
              #{custom_install_command}
            INSTALL
          else
            info('Installing puppet, will try to determine platform os')
            # need to add a CR to avoid trouble with proxy settings concatenation
            <<-INSTALL

              #{custom_pre_install_command}
              if [ ! $(which puppet) ]; then
                if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ]; then
                    #{install_puppet_yum_repo}
                else
                  if [ -f /etc/system-release ] || grep -q 'Amazon Linux' /etc/system-release; then
                     #{install_puppet_yum_repo}
                  else
                    #{sudo('apt-get')} -y install wget
                    #{sudo('apt-get')} -y install apt-transport-https
                    #{sudo('wget')} #{wget_proxy_parm} #{puppet_apt_repo}
                    #{sudo('dpkg')} -i #{puppet_apt_repo_file}
                    #{update_packages_debian_cmd}
                    #{sudo_env('apt-get')} -y install facter#{facter_debian_version}
                    #{sudo_env('apt-get')} -y install puppet-common#{puppet_debian_version}
                    #{sudo_env('apt-get')} -y install puppet#{puppet_debian_version}
                    #{install_hiera}
                  fi
                fi
              fi
              #{install_eyaml}
              #{install_eyaml_gpg}
              #{install_deep_merge}
              #{install_busser}
              #{custom_install_command}
            INSTALL
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def install_command_collections
        case puppet_platform
        when 'debian', 'ubuntu'
          info("Installing Puppet Collections on #{puppet_platform}")
          <<-INSTALL

          #{Util.shell_helpers}
          #{custom_pre_install_command}
          if [ ! -d "#{config[:puppet_coll_remote_path]}" ]; then
            if [ ! -f "#{config[:puppet_apt_collections_repo]}" ]; then
              #{sudo('apt-get')} -y install wget
              #{sudo('apt-get')} -y install apt-transport-https
              #{sudo('wget')} #{wget_proxy_parm} #{config[:puppet_apt_collections_repo]}
            fi
            #{sudo('dpkg')} -i #{puppet_apt_coll_repo_file}
            #{sudo('apt-get')} update
            #{sudo_env('apt-get')} -y install puppet-agent#{puppet_debian_version}
          fi
          #{install_eyaml("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
          #{install_eyaml_gpg("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
          #{install_deep_merge}
          #{install_busser}
          #{custom_install_command}
          INSTALL
        when 'redhat', 'centos', 'fedora', 'oracle', 'amazon'
          info("Installing Puppet Collections on #{puppet_platform}")
          <<-INSTALL

          #{Util.shell_helpers}
          #{custom_pre_install_command}
          if [ ! -d "#{config[:puppet_coll_remote_path]}" ]; then
            echo "-----> #{sudo_env('yum')} -y --nogpgcheck install #{config[:puppet_yum_collections_repo]}"
            #{sudo_env('yum')} clean all
            #{sudo_env('yum')} -y --nogpgcheck install #{config[:puppet_yum_collections_repo]}
            #{sudo_env('yum')} -y --nogpgcheck install puppet-agent#{puppet_redhat_version}
          fi
          #{install_eyaml("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
          #{install_eyaml_gpg("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
          #{install_deep_merge}
          #{install_busser}
          #{custom_install_command}
          INSTALL
        when /^windows.*/
          info("Installing Puppet Collections on #{puppet_platform}")
          info('Powershell is not recognised by core test-kitchen assuming it is present') unless powershell_shell?
          <<-INSTALL
            #{custom_pre_install_command}
            if(Get-Command puppet -ErrorAction 0) { return; }
            $architecture = if( [Environment]::Is64BitOperatingSystem ) { 'x64' } else { 'x86' }
            if( '#{puppet_windows_version}' -eq 'latest' ) {
                $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet-agent-${architecture}-latest.msi"
            } elseif( '#{puppet_windows_version}' -match '(\\d)\\.' ) {
                $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet$($Matches[1])/puppet-agent-#{puppet_windows_version}-${architecture}.msi"
            } else {
                $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet-agent-#{puppet_windows_version}-${architecture}.msi"
            }
            Invoke-WebRequest $MsiUrl -UseBasicParsing -OutFile "C:/puppet-agent.msi" #{posh_proxy_parm}
            $process = Start-Process -FilePath msiexec.exe -Wait -PassThru -ArgumentList '/qn', '/norestart', '/i', 'C:\\puppet-agent.msi'
            if ($process.ExitCode -ne 0) {
                Write-Host "Installer failed."
                Exit 1
            }
            #{install_busser}
            #{custom_install_command}
          INSTALL
        else
          info('Installing Puppet Collections, will try to determine platform os')
          <<-INSTALL

            #{Util.shell_helpers}
            #{custom_pre_install_command}
            if [ ! -d "#{config[:puppet_coll_remote_path]}" ]; then
              if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || \
                 [ -f /etc/system-release ] || grep -q 'Amazon Linux' /etc/system-release; then
                echo "-----> #{sudo_env('yum')} -y --nogpgcheck install #{config[:puppet_yum_collections_repo]}"
                #{sudo_env('yum')} -y --nogpgcheck install #{config[:puppet_yum_collections_repo]}
                #{sudo_env('yum')} -y --nogpgcheck install puppet-agent#{puppet_redhat_version}
              else
                #{sudo('apt-get')} -y install wget
                #{sudo('apt-get')} -y install apt-transport-https
                #{sudo('wget')} #{wget_proxy_parm} #{config[:puppet_apt_collections_repo]}
                #{sudo('dpkg')} -i #{puppet_apt_coll_repo_file}
                #{sudo('apt-get')} update
                #{sudo_env('apt-get')} -y install puppet-agent#{puppet_debian_version}
              fi
            fi
            #{install_eyaml("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
            #{install_eyaml_gpg("#{config[:puppet_coll_remote_path]}/puppet/bin/gem")}
            #{install_deep_merge}
            #{install_busser}
            #{custom_install_command}
          INSTALL
        end
      end

      def install_deep_merge
        return unless config[:hiera_deep_merge]
        <<-INSTALL
          # Support for hash merge lookups to recursively merge hash keys
          if [[ $(#{sudo('gem')} list deep_merge -i) == 'false' ]]; then
            echo '-----> Installing deep_merge to provide deep_merge of hiera hashes'
            #{sudo('gem')} install #{gem_proxy_parm} --no-ri --no-rdoc deep_merge
          fi
        INSTALL
      end

      def install_eyaml(gem_cmd = 'gem')
        return unless config[:hiera_eyaml]
        <<-INSTALL
          # A backend for Hiera that provides per-value asymmetric encryption of sensitive data
          if [[ $(#{sudo(gem_cmd)} list hiera-eyaml -i) == 'false' ]]; then
            echo '-----> Installing hiera-eyaml to provide encryption of hiera data'
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc highline -v 1.6.21
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc hiera-eyaml
          fi
        INSTALL
      end

      def install_eyaml_gpg(gem_cmd = 'gem')
        return unless config[:hiera_eyaml_gpg]
        <<-INSTALL
          # A backend for Hiera that provides per-value asymmetric encryption of sensitive data
          if [[ $(#{sudo(gem_cmd)} list hiera-eyaml-gpg -i) == 'false' ]]; then
            echo '-----> Installing hiera-eyaml-gpg to provide encryption of hiera data'
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc highline -v 1.6.21
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc hiera-eyaml
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc hiera-eyaml-gpg
            #{sudo(gem_cmd)} install #{gem_proxy_parm} --no-ri --no-rdoc ruby_gpg
          fi
        INSTALL
      end

      def install_busser
        return unless config[:require_chef_for_busser]
        info("Install busser on #{puppet_platform}")
        case puppet_platform
        when /^windows.*/
          # https://raw.githubusercontent.com/opscode/knife-windows/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb
          <<-INSTALL
            $webclient = New-Object System.Net.WebClient;  $webclient.DownloadFile('https://opscode-omnibus-packages.s3.amazonaws.com/windows/2008r2/x86_64/chef-windows-11.12.8-1.windows.msi','chef-windows-11.12.8-1.windows.msi')
            msiexec /qn /i chef-windows-11.12.8-1.windows.msi

            cmd.exe /C "SET PATH=%PATH%;`"C:\\opscode\\chef\\embedded\\bin`";`"C:\\tmp\\busser\\gems\\bin`""

          INSTALL
        else
          <<-INSTALL
          #{Util.shell_helpers}
          # install chef omnibus so that busser works as this is needed to run tests :(
          # TODO: work out how to install enough ruby
          # and set busser: { :ruby_bindir => '/usr/bin/ruby' } so that we dont need the
          # whole chef client
          if [ ! -d "/opt/chef" ]
          then
            echo '-----> Installing Chef Omnibus to install busser to run tests'
            #{export_http_proxy_parm}
            #{export_https_proxy_parm}
            #{export_no_proxy_parm}
            do_download #{chef_url} /tmp/install.sh
            #{sudo('sh')} /tmp/install.sh
          fi
          INSTALL
        end
      end

      def install_omnibus_command
        info('Installing puppet using puppet omnibus')

        version = ''
        version = "-v #{config[:puppet_version]}" unless config[:puppet_version].nil?

        <<-INSTALL
        #{Util.shell_helpers}
        if [ ! $(which puppet) ]; then
          echo "-----> Installing Puppet Omnibus"
          #{export_http_proxy_parm}
          #{export_https_proxy_parm}
          #{export_no_proxy_parm}
          do_download #{config[:puppet_omnibus_url]} /tmp/install_puppet.sh
          #{sudo_env('sh')} /tmp/install_puppet.sh #{version}
        fi
        INSTALL
      end

      def install_hiera
        return unless config[:install_hiera]
        <<-INSTALL
        #{sudo_env('apt-get')} -y install #{hiera_package}
        INSTALL
      end

      def hiera_package
        "#{config[:hiera_package]}#{puppet_hiera_debian_version}"
      end

      # /bin/wget -P /etc/pki/rpm-gpg/ http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
      # changed to curl

      def install_puppet_yum_repo
        <<-INSTALL
          rhelversion=$(cat /etc/redhat-release | grep 'release 7')
          # For CentOS7/RHEL7 the rdo release contains puppetlabs repo, creating conflict. Create temp-repo
          #{sudo_env('curl')} -o /etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
          if [ -n "$rhelversion" ]; then
          echo '[puppettemp-products]
          name=Puppet Labs Products - \$basearch
          baseurl=http://yum.puppetlabs.com/el/7/products/\$basearch
          gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
          enabled=0
          gpgcheck=1
          [puppettemp-deps]
          name=Puppet Labs Dependencies - \$basearch
          baseurl=http://yum.puppetlabs.com/el/7/dependencies/\$basearch
          gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
          enabled=0
          gpgcheck=1' | sudo tee /etc/yum.repos.d/puppettemp.repo > /dev/null
          sudo sed -i 's/^[ \t]*//' /etc/yum.repos.d/puppettemp.repo
            #{update_packages_redhat_cmd}
            #{sudo_env('yum')} -y --enablerepo=puppettemp-products --enablerepo=puppettemp-deps install puppet#{puppet_redhat_version}
            # Clean up temporary puppet repo
            sudo rm -rf /etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
            sudo rm -rf /etc/yum.repos.d/puppettemp.repo
          else
            #{sudo('rpm')} -ivh #{proxy_parm} #{puppet_yum_repo}
            #{update_packages_redhat_cmd}
            #{sudo_env('yum')} -y --nogpgcheck install puppet#{puppet_redhat_version}
          fi
        INSTALL
      end

      def custom_pre_install_command
        <<-INSTALL
          #{config[:custom_pre_install_command]}
        INSTALL
      end

      def custom_install_command
        <<-INSTALL
          #{config[:custom_install_command]}
        INSTALL
      end

      def init_command
        todelete = %w[modules manifests files hiera hiera.yaml hiera.global.yaml facter spec enc environment]
                   .map { |dir| File.join(config[:root_path], dir) }
        todelete += [hiera_data_remote_path,
                     '/etc/hiera.yaml',
                     "#{puppet_dir}/hiera.yaml",
                     spec_files_remote_path.to_s,
                     "#{puppet_dir}/fileserver.conf"]
        todelete << File.join(puppet_dir, puppet_environment) if puppet_environment
        todelete << File.join(puppet_environmentpath_remote_path, puppet_environment) if puppet_environment_config && puppet_environment
        cmd = "#{sudo(rm_command_paths(todelete))};"
        cmd += " #{mkdir_command} #{config[:root_path]};"
        cmd += " #{sudo(mkdir_command)} #{puppet_dir}"
        debug(cmd)
        cmd
      end

      def create_sandbox
        super
        debug("Creating local sandbox in #{sandbox_path}")
        yield if block_given?
        prepare_modules
        prepare_manifests
        prepare_files
        prepare_facter_file
        prepare_facts
        prepare_puppet_config
        prepare_hiera_config
        prepare_puppet_environment
        prepare_fileserver_config
        prepare_hiera_data
        prepare_enc
        prepare_spec_files
        info('Finished Preparing files for transfer')
      end

      def cleanup_sandbox
        return if sandbox_path.nil?
        debug("Cleaning up local sandbox in #{sandbox_path}")
        FileUtils.rmtree(sandbox_path)
        return if remove_repo.nil?
        debug("Cleaning up remote sandbox: #{remove_repo}")
        instance.remote_exec remove_repo
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def prepare_command
        commands = []
        if puppet_git_init
          commands << [
            sudo('rm -rf'), '/etc/puppet'
          ].join(' ')

          commands << [
            sudo('git clone'), puppet_git_init, '/etc/puppet'
          ].join(' ')
        end

        if puppet_git_pr
          commands << [
            sudo('git'),
            '--git-dir=/etc/puppet/.git/',
            'fetch -f',
            'origin',
            "pull/#{puppet_git_pr}/head:pr_#{puppet_git_pr}"
          ].join(' ')

          commands << [
            sudo('git'),
            '--git-dir=/etc/puppet/.git/',
            '--work-tree=/etc/puppet/',
            'checkout',
            "pr_#{puppet_git_pr}"
          ].join(' ')
        end

        if puppet_config
          commands << [
            sudo(cp_command),
            File.join(config[:root_path], 'puppet.conf'),
            puppet_dir
          ].join(' ')
        end

        if fileserver_config
          commands << [
            sudo(cp_command),
            File.join(config[:root_path], 'fileserver.conf'),
            puppet_dir
          ].join(' ')
        end

        if hiera_data
          commands << [
            sudo(mkdir_command), hiera_data_remote_path
          ].join(' ')
          commands << [
            sudo("#{cp_command} -r"), File.join(config[:root_path], 'hiera/*'), hiera_data_remote_path
          ].join(' ')
        end

        if hiera_eyaml
          commands << [
            sudo(mkdir_command), hiera_eyaml_key_remote_path
          ].join(' ')
          commands << [
            sudo("#{cp_command} -r"), File.join(config[:root_path], 'hiera_keys/*'), hiera_eyaml_key_remote_path
          ].join(' ')
        end

        if hiera_eyaml_gpg
          commands << [
            sudo('mkdir -p'), hiera_eyaml_gpg_remote_path
          ].join(' ')
          commands << [
            sudo('cp -r'), File.join(config[:root_path], hiera_eyaml_gpg_recipients), hiera_eyaml_gpg_remote_path
          ].join(' ')
          commands << [
            sudo('cp -r'), File.join(config[:root_path], hiera_eyaml_gpg_secring), hiera_eyaml_gpg_remote_path
          ].join(' ')
          commands << [
            sudo('cp -r'), File.join(config[:root_path], hiera_eyaml_gpg_pubring), hiera_eyaml_gpg_remote_path
          ].join(' ')
        end

        if puppet_environment
          commands << [
            sudo('ln -s '), config[:root_path], File.join(puppet_dir, puppet_environment)
          ].join(' ')
        end

        if puppet_environment_config && puppet_environment
          commands << [
            sudo(mkdir_command), puppet_environmentpath_remote_path
          ].join(' ')
          commands << [
            sudo(mkdir_command), File.join(puppet_environmentpath_remote_path, puppet_environment)
          ].join(' ')
          commands << [
            sudo('ln -s '), File.join(config[:root_path], 'modules'), File.join(puppet_environmentpath_remote_path, puppet_environment, puppet_environment_remote_modules_path)
          ].join(' ')
          commands << [
            sudo('ln -s '), File.join(config[:root_path], 'manifests'), File.join(puppet_environmentpath_remote_path, puppet_environment, puppet_environment_remote_manifests_path)
          ].join(' ')
          commands << [
            sudo('ln -s '), File.join(config[:root_path], 'hiera'), File.join(puppet_environmentpath_remote_path, puppet_environment, puppet_environment_remote_hieradata_path)
          ].join(' ')
          commands << [
            sudo('cp'), File.join(config[:root_path], 'environment', 'environment.conf'), File.join(puppet_environmentpath_remote_path, puppet_environment, 'environment.conf')
          ].join(' ')
          commands << [
            sudo('cp'), File.join(config[:root_path], 'environment', 'hiera.yaml'), File.join(puppet_environmentpath_remote_path, puppet_environment, 'hiera.yaml')
          ].join(' ')
        end

        if spec_files_path && spec_files_remote_path
          commands << [
            sudo(mkdir_command), spec_files_remote_path
          ].join(' ')
          commands << [
            sudo("#{cp_command} -r"), File.join(config[:root_path], 'spec/*'), spec_files_remote_path
          ].join(' ')
        end

        if config[:puppet_enc]
          commands << [
            sudo('chmod 755'), File.join("#{config[:root_path]}/enc", File.basename(config[:puppet_enc]))
          ].join(' ')
        end

        command = powershell? ? commands.join('; ') : commands.join(' && ')
        debug(command)
        command
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def run_command
        return config[:puppet_apply_command] unless config[:puppet_apply_command].nil?
        result = [
          facterlib,
          custom_facts,
          puppet_manifestdir,
          puppet_cmd,
          'apply',
          File.join(config[:root_path], 'manifests', manifest),
          "--modulepath=#{File.join(config[:root_path], 'modules')}",
          "--fileserverconfig=#{File.join(config[:root_path], 'fileserver.conf')}",
          custom_options,
          puppet_environment_flag,
          puppet_noop_flag,
          puppet_enc_flag,
          puppet_hiera_flag,
          puppet_detailed_exitcodes_flag,
          puppet_verbose_flag,
          puppet_debug_flag,
          puppet_logdest_flag,
          puppet_future_parser_flag,
          puppet_show_diff_flag,
          puppet_whitelist_exit_code
        ].join(' ')
        if config[:custom_post_apply_command]
          custom_post_apply_trap = <<-TRAP
            function custom_post_apply_command {
              #{config[:custom_post_apply_command]}
            }
            trap custom_post_apply_command EXIT
          TRAP
        end
        result = <<-RUN
          #{config[:custom_pre_apply_command]}
          #{custom_post_apply_trap}
          #{result}
        RUN
        info("Going to invoke puppet apply with: #{result}")
        result
      end

      protected

      def load_needed_dependencies!
        return unless File.exist?(puppetfile)
        return unless config[:resolve_with_librarian_puppet] || config[:resolve_with_r10k]
        if config[:resolve_with_librarian_puppet]
          require 'kitchen/provisioner/puppet/librarian'
          debug("Puppetfile found at #{puppetfile}, loading Librarian-Puppet")
          Puppet::Librarian.load!(logger)
        elsif config[:resolve_with_r10k]
          require 'kitchen/provisioner/puppet/r10k'
          debug("Puppetfile found at #{puppetfile}, loading R10K")
          Puppet::R10K.load!(logger)
        end
      end

      def tmpmodules_dir
        File.join(sandbox_path, 'modules')
      end

      def puppetfile
        config[:puppetfile_path] || ''
      end

      def modulefile
        config[:modulefile_path] || ''
      end

      def metadata_json
        config[:metadata_json_path] || ''
      end

      def manifest
        config[:manifest]
      end

      def manifests
        config[:manifests_path]
      end

      def modules
        config[:modules_path]
      end

      def files
        config[:files_path] || 'files'
      end

      def puppet_config
        config[:puppet_config_path]
      end

      def puppet_environment
        config[:puppet_environment]
      end

      def puppet_environment_config
        if config[:puppet_environment_config_path] && !puppet_environment
          raise("ERROR: found environment config '#{config[:puppet_environment_config_path]}', however no 'puppet_environment' is specified. Please specify 'puppet_environment' or unset 'puppet_environment_config_path' in .kitchen.yml")
        end
        config[:puppet_environment_config_path]
      end

      def puppet_environment_remote_modules_path
        config[:puppet_environment_remote_modules_path]
      end

      def puppet_environment_remote_manifests_path
        config[:puppet_environment_remote_manifests_path]
      end

      def puppet_environment_remote_hieradata_path
        config[:puppet_environment_remote_hieradata_path]
      end

      def puppet_git_init
        config[:puppet_git_init]
      end

      def puppet_git_pr
        config[:puppet_git_pr]
      end

      def hiera_config
        config[:hiera_config_path]
      end

      def puppet_environment_hiera_config
        config[:puppet_environment_hiera_config_path]
      end

      def fileserver_config
        config[:fileserver_config_path]
      end

      def hiera_data
        config[:hiera_data_path]
      end

      def hiera_data_remote_path
        return config[:hiera_data_remote_path] if config[:hiera_data_remote_path]

        if config[:require_puppet_collections]
          powershell? ? 'C:/ProgramData/PuppetLabs/code/environments/production/hieradata' : '/etc/puppetlabs/code/environments/production/hieradata'
        else
          powershell? ? 'C:/ProgramData/PuppetLabs/hiera/var' : '/var/lib/hiera'
        end
      end

      def hiera_writer
        config[:hiera_writer_files]
      end

      def hiera_eyaml
        config[:hiera_eyaml]
      end

      def hiera_eyaml_gpg
        config[:hiera_eyaml_gpg]
      end

      def hiera_eyaml_gpg_recipients
        config[:hiera_eyaml_gpg_recipients]
      end

      def hiera_eyaml_gpg_secring
        config[:hiera_eyaml_gpg_secring]
      end

      def hiera_eyaml_gpg_pubring
        config[:hiera_eyaml_gpg_pubring]
      end

      def hiera_eyaml_gpg_remote_path
        config[:hiera_eyaml_gpg_remote_path]
      end

      def hiera_eyaml_key_path
        config[:hiera_eyaml_key_path]
      end

      def hiera_eyaml_key_remote_path
        config[:hiera_eyaml_key_remote_path]
      end

      def hiera_deep_merge
        config[:hiera_deep_merge]
      end

      def librarian_puppet_ssl_file
        config[:librarian_puppet_ssl_file]
      end

      def r10k_ssl_file
        config[:r10k_puppet_ssl_file] || config[:librarian_puppet_ssl_file]
      end

      def puppet_cmd
        return '& "C:\Program Files\Puppet Labs\Puppet\bin\puppet"' if powershell?

        puppet_bin = config[:require_puppet_collections] ? "#{config[:puppet_coll_remote_path]}/bin/puppet" : config[:puppet_binary]

        if config[:puppet_no_sudo]
          puppet_bin
        else
          sudo_env(puppet_bin)
        end
      end

      def puppet_dir
        return 'C:/ProgramData/PuppetLabs/puppet/etc' if powershell?
        config[:require_puppet_collections] ? '/etc/puppetlabs/puppet' : '/etc/puppet'
      end

      def puppet_environmentpath_remote_path
        return config[:puppet_environmentpath_remote_path] if config[:puppet_environmentpath_remote_path]
        if config[:puppet_version] =~ /^3/
          powershell? ? 'C:/ProgramData/PuppetLabs/puppet/etc' : '/etc/puppet/environments'
        else
          powershell? ? 'C:/ProgramData/PuppetLabs/code/environments' : '/etc/puppetlabs/code/environments'
        end
      end

      def hiera_config_dir
        return 'C:/ProgramData/PuppetLabs/puppet/etc' if powershell?
        config[:require_puppet_collections] ? '/etc/puppetlabs/code' : '/etc/puppet'
      end

      def puppet_debian_version
        config[:puppet_version] ? "=#{config[:puppet_version]}" : nil
      end

      def facter_debian_version
        config[:facter_version] ? "=#{config[:facter_version]}" : nil
      end

      def puppet_hiera_debian_version
        config[:hiera_version] ? "=#{config[:hiera_version]}" : nil
      end

      def puppet_redhat_version
        if puppet_platform == 'amazon'
          config[:puppet_version]
        else
          config[:puppet_version] ? "-#{config[:puppet_version]}" : nil
        end
      end

      def puppet_windows_version
        config[:puppet_version] ? config[:puppet_version].to_s : 'latest'
      end

      def puppet_environment_flag
        if config[:puppet_version] =~ /^2/
          config[:puppet_environment] ? "--environment=#{puppet_environment}" : nil
        else
          config[:puppet_environment] ? "--environment=#{puppet_environment} --environmentpath=#{puppet_environmentpath_remote_path}" : nil
        end
      end

      def puppet_manifestdir
        return nil if config[:require_puppet_collections]
        return nil if config[:puppet_environment]
        return nil if powershell?
        bash_vars = "export MANIFESTDIR='#{File.join(config[:root_path], 'manifests')}';"
        debug(bash_vars)
        bash_vars
      end

      def custom_options
        config[:custom_options] || ''
      end

      def puppet_noop_flag
        config[:puppet_noop] ? '--noop' : nil
      end

      def puppet_debug_flag
        config[:puppet_debug] ? '-d' : nil
      end

      def puppet_verbose_flag
        config[:puppet_verbose] ? '-v' : nil
      end

      def puppet_show_diff_flag
        config[:puppet_show_diff] ? '--show_diff' : nil
      end

      def puppet_future_parser_flag
        config[:puppet_future_parser] ? '--parser=future' : nil
      end

      def puppet_logdest_flag
        return nil unless config[:puppet_logdest]
        destinations = ''
        config[:puppet_logdest].each do |dest|
          destinations << "--logdest #{dest} "
        end
        destinations
      end

      def puppet_platform
        config[:platform].gsub(/-.*/, '')
      end

      def update_packages_debian_cmd
        config[:update_package_repos] ? "#{sudo_env('apt-get')} update" : nil
      end

      def update_packages_redhat_cmd
        # #{sudo('yum')}
        config[:update_package_repos] ? "#{sudo_env('yum')} makecache" : nil
      end

      def sudo_env(pm)
        s = https_proxy ? "https_proxy=#{https_proxy}" : nil
        p = http_proxy ? "http_proxy=#{http_proxy}" : nil
        n = no_proxy ? "no_proxy=#{no_proxy}" : nil
        p || s ? "#{sudo('env')} #{p} #{s} #{n} #{pm}" : sudo(pm).to_s
      end

      def remove_puppet_repo
        config[:remove_puppet_repo]
      end

      def spec_files_path
        config[:spec_files_path]
      end

      def spec_files_remote_path
        config[:spec_files_remote_path]
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def facterlib
        factpath = nil
        factpath = File.join(config[:root_path], 'facter').to_s if config[:install_custom_facts] && config[:custom_facts].any?
        factpath = File.join(config[:root_path], 'facter').to_s if config[:facter_file]
        factpath = "#{factpath}:" if config[:facterlib] && !factpath.nil?
        factpath = "#{factpath}#{config[:facterlib]}" if config[:facterlib]
        return nil if factpath.nil?
        bash_vars = "export FACTERLIB='#{factpath}';"
        debug(bash_vars)
        bash_vars
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def custom_facts
        return nil if config[:custom_facts].none?
        return nil if config[:install_custom_facts]
        if powershell?
          environment_vars = config[:custom_facts].map { |k, v| "$env:FACTER_#{k}='#{v}'" }.join('; ')
          environment_vars = "#{environment_vars};"
        else
          environment_vars = config[:custom_facts].map { |k, v| "FACTER_#{k}=#{v}" }.join(' ')
          environment_vars = "export #{environment_vars};"
        end
        debug(environment_vars)
        environment_vars
      end

      def puppet_enc_flag
        config[:puppet_enc] ? "--node_terminus=exec --external_nodes=#{config[:root_path]}/enc/#{File.basename(config[:puppet_enc])}" : nil
      end

      def puppet_hiera_flag
        hiera_config ? "--hiera_config=#{config[:root_path]}/hiera.global.yaml" : nil
      end

      def puppet_detailed_exitcodes_flag
        config[:puppet_detailed_exitcodes] ? '--detailed-exitcodes' : nil
      end

      def remove_repo
        remove_puppet_repo ? "#{sudo('rm')} -rf /tmp/kitchen #{hiera_data_remote_path} #{hiera_eyaml_key_remote_path} #{puppet_dir}/* " : nil
      end

      def puppet_whitelist_exit_code
        if config[:puppet_whitelist_exit_code].nil?
          powershell? ? '; exit $LASTEXITCODE' : nil
        elsif powershell?
          "; if(@(#{[config[:puppet_whitelist_exit_code]].join(', ')}) -contains $LASTEXITCODE) {exit 0} else {exit $LASTEXITCODE}"
        else
          '; RC=$?; [ ' + [config[:puppet_whitelist_exit_code]].flatten.map { |x| "\$RC -eq #{x}" }.join(' -o ') + ' ] && exit 0; exit $RC'
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def puppet_apt_repo
        platform_version = config[:platform].partition('-')[2]
        case puppet_platform
        when 'ubuntu'
          case platform_version
	  when '20.04'
            # focal Repo
            'https://apt.puppetlabs.com/puppet-release-focal.deb'
          when '18.04'
            # bionic Repo
            'https://apt.puppetlabs.com/puppet-release-bionic.deb'
          when '16.04'
            # xenial Repo
            'https://apt.puppetlabs.com/puppet-release-xenial.deb'          
          when '14.10'
            # Utopic Repo
            'https://apt.puppetlabs.com/puppetlabs-release-utopic.deb'
          when '14.04'
            # Trusty Repo
            'https://apt.puppetlabs.com/puppetlabs-release-trusty.deb'
          when '12.04'
            # Precise Repo
            'https://apt.puppetlabs.com/puppetlabs-release-precise.deb'
          else
            # Configured Repo
            config[:puppet_apt_repo]
          end
        when 'debian'
          case platform_version.gsub(/\..*/, '')
 	   when '10'
             # Debian buster
             'https://apt.puppetlabs.com/puppet-tools-release-buster.deb'
           when '9'
             # Debian xenial
            'https://apt.puppetlabs.com/puppet-tools-release-stretch.deb'
          when '8'
            # Debian Jessie
            'https://apt.puppetlabs.com/puppetlabs-release-jessie.deb'
          when '7'
            # Debian Wheezy
            'https://apt.puppetlabs.com/puppetlabs-release-wheezy.deb'
          when '6'
            # Debian Squeeze
            'https://apt.puppetlabs.com/puppetlabs-release-squeeze.deb'
          else
            # Configured Repo
            config[:puppet_apt_repo]
          end
        else
          debug("Apt repo detection failed with platform - #{config[:platform]}")
          false
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def puppet_apt_repo_file
        puppet_apt_repo.split('/').last if puppet_apt_repo
      end

      def puppet_apt_coll_repo_file
        config[:puppet_apt_collections_repo].split('/').last
      end

      def puppet_yum_repo
        config[:puppet_yum_repo]
      end

      def proxy_parm
        http_proxy ? "--httpproxy #{URI.parse(http_proxy).host.downcase} --httpport #{URI.parse(http_proxy).port} " : nil
      end

      def gem_proxy_parm
        p = http_proxy ? "--http-proxy #{http_proxy}" : nil
        n = no_proxy ? "--no-http-proxy #{no_proxy}" : nil
        p || n ? "#{p} #{n}" : nil
      end

      def wget_proxy_parm
        p = http_proxy ? "-e http_proxy=#{http_proxy}" : nil
        s = https_proxy ? "-e https_proxy=#{https_proxy}" : nil
        n = no_proxy ? "-e no_proxy=#{no_proxy}" : nil
        p || s ? "-e use_proxy=yes #{p} #{s} #{n}" : nil
      end

      def posh_proxy_parm
        http_proxy ? "-Proxy #{http_proxy}" : nil
      end

      def powershell?
        return true if powershell_shell?
        return true if puppet_platform =~ /^windows.*/
        false
      end

      def export_http_proxy_parm
        http_proxy ? "export http_proxy=#{http_proxy}" : nil
      end

      def export_https_proxy_parm
        https_proxy ? "export https_proxy=#{https_proxy}" : nil
      end

      def export_no_proxy_parm
        no_proxy ? "export no_proxy=#{no_proxy}" : nil
      end

      def http_proxy
        config[:http_proxy]
      end

      def https_proxy
        config[:https_proxy]
      end

      def no_proxy
        config[:no_proxy]
      end

      def chef_url
        config[:chef_bootstrap_url]
      end

      def prepare_manifests
        info('Preparing manifests')
        debug("Using manifests from #{manifests}")

        tmp_manifests_dir = File.join(sandbox_path, 'manifests')
        FileUtils.mkdir_p(tmp_manifests_dir)
        FileUtils.cp_r(Dir.glob("#{manifests}/*"), tmp_manifests_dir)
      end

      def prepare_files
        info('Preparing files')
        unless File.directory?(files)
          info 'nothing to do for files'
          return
        end

        debug("Using files from #{files}")

        tmp_files_dir = File.join(sandbox_path, 'files')
        FileUtils.mkdir_p(tmp_files_dir)
        FileUtils.cp_r(Dir.glob("#{files}/*"), tmp_files_dir)
      end

      def prepare_facter_file
        return unless config[:facter_file]
        info 'Copying facter file'
        facter_dir = File.join(sandbox_path, 'facter')
        FileUtils.mkdir_p(facter_dir)
        FileUtils.cp_r(config[:facter_file], facter_dir)
      end

      def prepare_facts
        return unless config[:install_custom_facts]
        return unless config[:custom_facts]
        info 'Installing custom facts'
        facter_dir = File.join(sandbox_path, 'facter')
        FileUtils.mkdir_p(facter_dir)
        tmp_facter_file = File.join(facter_dir, 'kitchen.rb')
        facter_facts = Hash[config[:custom_facts]]
        File.open(tmp_facter_file, 'a') do |out|
          facter_facts.each do |k, v|
            out.write "\nFacter.add(:#{k}) do\n"
            out.write "  setcode do\n"
            if [Array, Hash].include? v.class
              out.write "    #{v}\n"
            else
              out.write "    \"#{v}\"\n"
            end
            out.write "  end\n"
            out.write "end\n"
          end
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def prepare_modules
        info('Preparing modules')

        FileUtils.mkdir_p(tmpmodules_dir)
        resolve_with_librarian if File.exist?(puppetfile) && config[:resolve_with_librarian_puppet]
        resolve_with_r10k if File.exist?(puppetfile) && config[:resolve_with_r10k] && !config[:resolve_with_librarian_puppet]
        modules_to_copy = {}

        # If root dir (.) is a module, add it for copying
        self_name = read_self_module_name
        modules_to_copy[self_name] = '.' if self_name

        if modules
          modules_array = modules.split(':')
          modules_array.each do |m_path|
            Dir.glob("#{m_path}/*").each do |m|
              name = File.basename(m)
              if modules_to_copy.include? name
                debug("Found duplicated module: #{name}. The path taking precedence: '#{modules_to_copy[name]}', ignoring '#{m}'")
              else
                modules_to_copy[name] = m
              end
            end
          end
        end

        if modules_to_copy.empty?
          info 'Nothing to do for modules'
        else
          copy_modules(modules_to_copy, tmpmodules_dir)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def copy_modules(modules, destination)
        excluded_paths = %w[modules pkg] + config[:ignored_paths_from_root]
        debug("Copying modules to directory: #{destination}")
        modules.each do |name, source|
          next unless File.directory?(source)
          debug("Copying module #{name} from #{source}...")
          target = "#{destination}/#{name}"
          FileUtils.mkdir_p(target) unless File.exist? target
          FileUtils.cp_r(
            Dir.glob("#{source}/*").reject { |entry| entry =~ /#{excluded_paths.join('$|')}$/ },
            target,
            remove_destination: true
          )
        end
      end

      def read_self_module_name
        if File.exist?(modulefile)
          warn('Modulefile found but this is deprecated, ignoring it, see https://tickets.puppetlabs.com/browse/PUP-1188')
        end

        return unless File.exist?(metadata_json)
        module_name = nil
        begin
          module_name = JSON.parse(IO.read(metadata_json))['name'].split('-').last
        rescue JSON::ParserError
          error("not able to load or parse #{metadata_json} for the name of the module")
        end

        module_name
      end

      def prepare_puppet_config
        return unless puppet_config

        info('Preparing puppet.conf')
        debug("Using puppet config from #{puppet_config}")

        FileUtils.cp_r(puppet_config, File.join(sandbox_path, 'puppet.conf'))
      end

      def prepare_enc
        return unless config[:puppet_enc]
        info 'Copying enc file'
        enc_dir = File.join(sandbox_path, 'enc')
        FileUtils.mkdir_p(enc_dir)
        FileUtils.cp_r(config[:puppet_enc], File.join(enc_dir, '/'))
      end

      def prepare_puppet_environment
        return unless puppet_environment_config

        info('Preparing Environment Config')
        environment_dir = File.join(sandbox_path, 'environment')
        FileUtils.mkdir_p(environment_dir)
        debug("Using Environment Config environment.conf from #{puppet_environment_config}")
        FileUtils.cp_r(puppet_environment_config, File.join(environment_dir, 'environment.conf'))
        if puppet_environment_hiera_config
          debug("Using Environment Hiera Config hiera.yaml from #{puppet_environment_hiera_config}")
          FileUtils.cp_r(puppet_environment_hiera_config, File.join(environment_dir, 'hiera.yaml'))
        else
          info('No Environment hiera.yaml found')
        end
      end

      def prepare_hiera_config
        return unless hiera_config

        info('Preparing hiera (global layer)')
        debug("Using hiera from #{hiera_config}")

        FileUtils.cp_r(hiera_config, File.join(sandbox_path, 'hiera.global.yaml'))
      end

      def prepare_fileserver_config
        return unless fileserver_config

        info('Preparing fileserver')
        debug("Using fileserver config from #{fileserver_config}")

        FileUtils.cp_r(fileserver_config, File.join(sandbox_path, 'fileserver.conf'))
      end

      def prepare_hiera_data
        return unless hiera_data
        info('Preparing hiera data')
        tmp_hiera_dir = File.join(sandbox_path, 'hiera')
        debug("Copying hiera data from #{hiera_data} to #{tmp_hiera_dir}")
        FileUtils.mkdir_p(tmp_hiera_dir)
        FileUtils.cp_r(Dir.glob("#{hiera_data}/*"), tmp_hiera_dir)
        if hiera_writer
          hiera_writer.each do |file|
            file.each do |filename, hiera_hash|
              debug("Creating hiera yaml file #{tmp_hiera_dir}/#{filename}")
              dir = File.join(tmp_hiera_dir, File.dirname(filename.to_s))
              FileUtils.mkdir_p(dir)
              output_file = open(File.join(dir, File.basename(filename.to_s)), 'w')
              # convert json and back before converting to yaml to recursively convert symbols to strings, heh
              output_file.write JSON[hiera_hash.to_json].to_yaml
              output_file.close
            end
          end
        end
        return unless hiera_eyaml_key_path
        tmp_hiera_key_dir = File.join(sandbox_path, 'hiera_keys')
        debug("Copying hiera eyaml keys from #{hiera_eyaml_key_path} to #{tmp_hiera_key_dir}")
        FileUtils.mkdir_p(tmp_hiera_key_dir)
        FileUtils.cp_r(Dir.glob("#{hiera_eyaml_key_path}/*"), tmp_hiera_key_dir)
      end

      def prepare_spec_files
        return unless spec_files_path
        info('Preparing spec files')
        tmp_spec_dir = File.join(sandbox_path, 'spec')
        debug("Copying specs from #{spec_files_path} to #{tmp_spec_dir}")
        FileUtils.mkdir_p(tmp_spec_dir)
        FileUtils.cp_r(Dir.glob(File.join(spec_files_path, '*')).reject { |entry| entry =~ /fixtures$/ }, tmp_spec_dir) if config[:ignore_spec_fixtures]
        FileUtils.cp_r(Dir.glob("#{spec_files_path}/*"), tmp_spec_dir) unless config[:ignore_spec_fixtures]
      end

      def resolve_with_librarian
        require 'kitchen/provisioner/puppet/librarian'
        Kitchen.mutex.synchronize do
          ENV['SSL_CERT_FILE'] = librarian_puppet_ssl_file if librarian_puppet_ssl_file
          Puppet::Librarian.new(puppetfile, tmpmodules_dir, logger).resolve
          ENV['SSL_CERT_FILE'] = '' if librarian_puppet_ssl_file
        end
      end

      def resolve_with_r10k
        require 'kitchen/provisioner/puppet/r10k'
        Kitchen.mutex.synchronize do
          ENV['SSL_CERT_FILE'] = r10k_ssl_file if r10k_ssl_file
          Puppet::R10K.new(puppetfile, tmpmodules_dir, logger).resolve
          ENV['SSL_CERT_FILE'] = '' if r10k_ssl_file
        end
      end

      def cp_command
        return 'cp -force' if powershell?
        'cp'
      end

      def rm_command
        return 'rm -force -recurse' if powershell?
        'rm -rf'
      end

      def mkdir_command
        return 'mkdir -force -path' if powershell?
        'mkdir -p'
      end

      def rm_command_paths(paths)
        return :nil if paths.length.zero?
        return "#{rm_command} \"#{paths.join('", "')}\"" if powershell?
        "#{rm_command} #{paths.join(' ')}"
      end
    end
  end
end
