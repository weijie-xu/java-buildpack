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

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/framework/ca_wily_agent'

describe JavaBuildpack::Framework::CAWilyAgent do
  include_context 'component_helper'

  it 'does not detect without ca-wily-n/a service' do
    expect(component.detect).to be_nil
  end

  context do

    before do
      allow(services).to receive(:one_service?).with(/ca-wily/, 'host-name', 'port', 'ssl', 'agent-name')
                           .and_return(true)
    end

    it 'detects with ca-wily-n/a service' do
      expect(component.detect).to eq("ca-wily-agent=#{version}")
    end

    it 'downloads CA Wily agent Zip',
       cache_fixture: 'stub-ca-wily-agent.zip' do

      component.compile

      expect(sandbox + 'wily.test').to exist
    end

    it 'copies resources',
       cache_fixture: 'stub-ca-wily-agent.zip' do

      component.compile

      expect(sandbox + 'IntroscopeAgent.default-osgi.profile').to exist
    end

    it 'updates JAVA_OPTS' do
      allow(services).to receive(:find_service).and_return('credentials' => { 'agent-name' => 'test-agent-name',
                                                                              'host-name'  => 'test-host-name',
                                                                              'port'       => 'test-port',
                                                                              'ssl'        => 'test-ssl' })

      component.release

      expect(java_opts).to include("-javaagent:$PWD/.java-buildpack/ca_wily_agent/ca_wily_agent-#{version}.jar")
      expect(java_opts).to include('-Dcom.wily.introscope.agent.agentName=test-agent-name-test-application-name')
      expect(java_opts).to include('-Dintroscope.agent.enterprisemanager.transport.tcp.host.DEFAULT=test-host-name')
      expect(java_opts).to include('-Dintroscope.agent.enterprisemanager.transport.tcp.port.DEFAULT=test-port')
      expect(java_opts).to include('-Dcom.wily.introscope.agentProfile=$PWD/.java-buildpack' \
                                   '/ca_wily_agent/core/config/IntroscopeAgent.default-osgi.profile')
    end

  end

end
