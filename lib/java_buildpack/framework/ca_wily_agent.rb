# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013-2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch AppDynamics support.
    class CAWilyAgent < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_zip false
        @droplet.copy_resources
        copy_custom_pbds
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        credentials = @application.services.find_service(FILTER)['credentials']
        java_opts   = @droplet.java_opts
        java_opts.add_javaagent(@droplet.sandbox + jar_name) # 'Agent.jar')

        add_system_properties java_opts
        set_agent_name(java_opts, credentials)
        add_profile java_opts
        host_name(java_opts, credentials)
        port(java_opts, credentials)
        add_ssl(java_opts, credentials)
        enable_dynamic_instrumentation java_opts
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @application.services.one_service? FILTER, HOST_NAME, PORT, SSL, AGENT_NAME
      end

      private

      FILTER = /ca-wily/.freeze

      AGENT_NAME = 'agent-name'.freeze

      HOST_NAME = 'host-name'.freeze

      PORT = 'port'.freeze

      SSL = 'ssl'.freeze

      APPLICATION_NAME = 'application_name'.freeze

      APPLICATION_URIS = 'application_uris'.freeze

      private_constant :FILTER, :AGENT_NAME, :HOST_NAME, :PORT, :SSL, :APPLICATION_NAME, :APPLICATION_URIS

      def add_system_properties(java_opts)
        java_opts.add_system_property('introscope.agent.defaultProcessName', @application.details[APPLICATION_NAME])
        java_opts.add_system_property('introscope.agent.hostName', @application.details[APPLICATION_URIS])
      end

      def application_name
        @application.details[APPLICATION_NAME]
      end

      def host_name(java_opts, credentials)
        host_name = credentials[HOST_NAME]
        fail "'host-name' credential must be set" unless host_name
        java_opts.add_system_property 'introscope.agent.enterprisemanager.transport.tcp.host.DEFAULT', host_name
      end

      def port(java_opts, credentials)
        port = credentials[PORT]
        fail "'port' credential must be set" unless port
        java_opts.add_system_property 'introscope.agent.enterprisemanager.transport.tcp.port.DEFAULT', port if port
      end

      def add_ssl(java_opts, credentials)
        ssl = credentials[SSL]
        fail "'ssl' credential must be set to either true or false" unless ssl
        default_socket_factory = 'com.wily.isengard.postofficehub.link.net.DefaultSocketFactory'
        ssl_socket_factory     = 'com.wily.isengard.postofficehub.link.net.SSLSocketFactory'

        socket_factory = ssl == true ? ssl_socket_factory : default_socket_factory

        java_opts.add_system_property 'introscope.agent.enterprisemanager.transport.tcp.socketfactory.DEFAULT',
                                      socket_factory
      end

      def set_agent_name(java_opts, credentials)
        prefix = credentials[AGENT_NAME]
        fail "'agent-name' credential must be set" unless prefix
        agent_name = [prefix, '-', application_name].join ''

        java_opts.add_system_property 'com.wily.introscope.agent.agentName', agent_name if agent_name
      end

      def add_profile(java_opts)
        profile_path = @droplet.sandbox + 'core/config/IntroscopeAgent.default-osgi.profile'
        java_opts.add_system_property 'com.wily.introscope.agentProfile', profile_path if profile_path
      end

      def copy_custom_pbds
        custom_pdb_files_dir = @application.root + 'META-INF/ca-wily'
        return unless custom_pdb_files_dir?
        puts '       Found the pbd directory META-INF/ca-wily and copying the files to hotdeploy folder'
        hotdeploy_dir = @droplet.sandbox + 'core/config/hotdeploy/'
        FileUtils.cp_r("#{custom_pdb_files_dir}/.", hotdeploy_dir)
      end

      def enable_dynamic_instrumentation(java_opts)
        return unless custom_pdb_files_dir?
        java_opts.add_system_property 'introscope.agent.remoteagentdynamicinstrumentation.enabled', 'true'
        java_opts.add_system_property 'introscope.autoprobe.dynamicinstrument.enabled', 'true'
      end

      def custom_pdb_files_dir?
        (@application.root + 'META-INF/ca-wily').exist?
      end

    end

  end
end
