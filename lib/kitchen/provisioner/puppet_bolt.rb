# -*- encoding: utf-8 -*-

#
# Author:: Neill Turner (<neillwturner@gmail.com>
#
# Copyright (C) 2017 Neill Turner
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
#

require 'uri'
require 'json'
require 'kitchen'

module Kitchen

  module Configurable
    def platform_name
      instance.platform.name
    end
  end

  module Provisioner
    #
    # Puppet Bolt provisioner.
    #
    class PuppetBolt < Base
#      attr_accessor :tmp_dir

      default_config :bolt_version, nil

      default_config :require_bolt_repo, true
      default_config :remove_bolt_repo, false

      default_config :custom_install_command, nil
      default_config :custom_pre_install_command, nil
      default_config :custom_pre_bolt_command, nil
      default_config :custom_post_bolt_command, nil

      default_config :require_bolt_omnibus, false

      default_config :bolt_commands, []
      default_config :platform, &:platform_name

      default_config :http_proxy, nil
      default_config :https_proxy, nil
      default_config :no_proxy, nil


      # for future use

      default_config :bolt_cmd, nil        # bolt command run <COMMAND>, bolt script run, bolt task run, bolt plan run, bolt file upload
      default_config :bolt_nodes, nil      # REQUIRED
      default_config :bolt_user, nil       # BOLT_USER env variable
      default_config :bolt_password, nil
      default_config :bolt_modulepath, [] # Required for tasks and plans. The path to the module containing the task. Separate multiple paths with a semicolon (;) on Windows or a colon (:) on all other platforms.
      default_config :bolt_params,nil
      default_config :bolt_tty,false
      default_config :bolt_insecure,true
      default_config :bolt_transport, nil

      # Install the dependencies for your platform.
      # On CentOS 7 or Red Hat Enterprise Linux 7, run yum install -y make gcc ruby-devel
      # On Fedora 25, run dnf install -y make gcc redhat-rpm-config ruby-devel rubygem-rdoc
      # On Debian 9 or Ubuntu 16.04, run apt-get install -y make gcc ruby-dev
      # On Mac OS X, run xcode-select --install
      # Install Bolt as a gem by running gem install bolt
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def install_command
        return unless config[:require_bolt_repo] || config[:require_bolt_omnibus]
        if config[:require_bolt_omnibus]
          install_omnibus_command
        else
          case bolt_platform
          when 'debian', 'ubuntu'
            info("Installing puppet on #{config[:platform]}")
            # need to add a CR to avoid trouble with proxy settings concatenation
            <<-INSTALL

              #{custom_pre_install_command}
              if [ ! $(which bolt) ]; then
                #{sudo('apt-get')} install -y make gcc ruby-dev
                #{install_bolt}
              fi
              #{custom_install_command}
            INSTALL
          when 'redhat', 'centos', 'oracle', 'amazon'
            info("Installing puppet from yum on #{bolt_platform}")
            # need to add a CR to avoid trouble with proxy settings concatenation
            <<-INSTALL

              #{custom_pre_install_command}
              if [ ! $(which bolt) ]; then
                #{sudo('yum')} install -y make gcc ruby-devel
                #{install_bolt}
              fi
              #{custom_install_command}
            INSTALL
          when 'fedora'
            info("Installing bolt from dnf on #{bolt_platform}")
            # need to add a CR to avoid trouble with proxy settings concatenation
            <<-INSTALL

              #{custom_pre_install_command}
              if [ ! $(which bolt) ]; then
                #{sudo('dnf')} install -y make gcc redhat-rpm-config ruby-devel rubygem-rdoc
                #{install_bolt}
              fi
              #{custom_install_command}
            INSTALL
          when /^windows.*/
            info("Installing puppet on #{bolt_platform}")
            info('Powershell is not recognised by core test-kitchen assuming it is present') unless powershell_shell?
            <<-INSTALL
              if(Get-Command bolt -ErrorAction 0) { return; }
              Write-Host "Disabling UAC..."
              New-ItemProperty -Path HKLM:Software\\Microsoft\Windows\\CurrentVersion\\Policies\\System -Name EnableLUA -PropertyType DWord -Value 0 -Force
              New-ItemProperty -Path HKLM:Software\\Microsoft\\Windows\\CurrentVersion\\Policies\System -Name ConsentPromptBehaviorAdmin -PropertyType DWord -Value 0 -Force
              Write-Host "Install Chocolatey...."
              iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
              Write-Host "Install Ruby...."
              choco install ruby
              refreshenv
              Write-Host "Install Bolt...."
              gem install bolt
            INSTALL
          else
            info('Installing bolt, will try to determine platform os')
            # need to add a CR to avoid trouble with proxy settings concatenation
            <<-INSTALL

              #{custom_pre_install_command}
              if [ ! $(which bolt) ]; then
                if [ -f  /etc/fedora-release ]; then
                    #{sudo('dnf')} install -y make gcc redhat-rpm-config ruby-devel rubygem-rdoc
                else
                  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ]; then
                      #{sudo('yum')} install -y make gcc ruby-devel
                  else
                    if [ -f /etc/system-release ] || [ grep -q 'Amazon Linux' /etc/system-release ]; then
                       #{sudo('yum')} install -y make gcc ruby-devel
                    else
                      #{sudo('apt-get')} install -y make gcc ruby-dev
                    fi
                  fi
                fi
                #{install_bolt}
              fi
              #{custom_install_command}
            INSTALL
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def install_omnibus_command
        error('Installing bolt using an omnibus install script not currently supported')
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

      def install_bolt
        if config[:bolt_version]
          <<-INSTALL
            #{sudo('gem')} install --no-rdoc --no-ri bolt -v #{config[:bolt_version]}
          INSTALL
        else
          <<-INSTALL
            #{sudo('gem')} install --no-rdoc --no-ri bolt
          INSTALL
        end
      end

      def init_command
        debug("Init Command")
      end

      def create_sandbox
        super
        debug("Creating local sandbox in #{sandbox_path}")
      end

      def cleanup_sandbox
        return if sandbox_path.nil?
        debug("Cleaning up local sandbox in #{sandbox_path}")
        FileUtils.rmtree(sandbox_path)
        return if remove_repo.nil?
        debug("Cleaning up remote sandbox: #{remove_repo}")
        instance.remote_exec remove_repo
      end

      def run_command
        if config[:custom_post_bolt_command]
          custom_post_bolt_trap = <<-TRAP
            function custom_post_bolt_command {
              #{config[:custom_post_bolt_command]}
            }
            trap custom_post_bolt_command EXIT
          TRAP
        end
        result = <<-RUN
          #{config[:custom_pre_bolt_command]}
          #{custom_post_bolt_trap}
        RUN
        bolt_commands_to_run.each do |a|
          result = <<-RUN
          #{result}
          #{a}
          RUN
        end
        info("Going to invoke bolt with: #{result}")
        result
      end

      protected

      def bolt_commands_to_run
        bolt_commands_to_run = []
        if config[:bolt_commands]
          bolt_commands_to_run = config[:bolt_commands].is_a?(Array) ? config[:bolt_commands] : [config[:bolt_commands]]
        end
      end

      def bolt_platform
        config[:platform].gsub(/-.*/, '')
      end

      def remove_repo
        config[:remove_bolt_repo] ? "#{sudo('rm')} -rf /tmp/kitchen " : nil
      end

      def sudo_env(pm)
        s = https_proxy ? "https_proxy=#{https_proxy}" : nil
        p = http_proxy ? "http_proxy=#{http_proxy}" : nil
        n = no_proxy ? "no_proxy=#{no_proxy}" : nil
        p || s ? "#{sudo('env')} #{p} #{s} #{n} #{pm}" : sudo(pm).to_s
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
        return true if bolt_platform =~ /^windows.*/
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
    end
  end
end
