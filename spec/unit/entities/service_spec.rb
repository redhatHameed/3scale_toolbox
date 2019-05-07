require '3scale_toolbox'

RSpec.describe ThreeScaleToolbox::Entities::Service do
  include_context :random_name
  let(:remote) { double('remote') }
  let(:common_error_response) { { 'errors' => { 'comp' => 'error' } } }
  let(:positive_response) { { 'errors' => nil, 'id' => 'some_id' } }

  context 'Service.create' do
    let(:system_name) { random_lowercase_name }
    let(:deployment_option) { 'hosted' }
    let(:service) do
      {
        'name' => random_lowercase_name,
        'deployment_option' => deployment_option,
        'system_name' => system_name,
      }
    end
    let(:service_info) { { remote: remote, service_params: service } }
    let(:expected_svc) { { 'name' => service['name'], 'system_name' => system_name } }

    it 'throws error on remote error' do
      expect(remote).to receive(:create_service).and_return(common_error_response)
      expect do
        described_class.create(service_info)
      end.to raise_error(ThreeScaleToolbox::Error, /Service has not been saved/)
    end

    context 'deployment mode invalid' do
      let(:invalid_deployment_error_response) do
        {
          'errors' => {
            'deployment_option' => ['is not included in the list']
          }
        }
      end

      it 'deployment config is removed' do
        expect(remote).to receive(:create_service).with(hash_including('deployment_option'))
                                                  .and_return(invalid_deployment_error_response)
        expect(remote).to receive(:create_service).with(hash_excluding('deployment_option'))
                                                  .and_return(positive_response)
        service_obj = described_class.create(service_info)
        expect(service_obj.id).to eq(positive_response['id'])
      end

      it 'throws error when second request returns error' do
        expect(remote).to receive(:create_service).with(hash_including('deployment_option'))
                                                  .and_return(invalid_deployment_error_response)
        expect(remote).to receive(:create_service).with(hash_excluding('deployment_option'))
                                                  .and_return(common_error_response)
        expect do
          described_class.create(service_info)
        end.to raise_error(ThreeScaleToolbox::Error, /Service has not been saved/)
      end
    end

    it 'throws deployment option error' do
      expect(remote).to receive(:create_service).and_return(common_error_response)
      expect do
        described_class.create(service_info)
      end.to raise_error(ThreeScaleToolbox::Error, /Service has not been saved/)
    end

    it 'service instance is returned' do
      expect(remote).to receive(:create_service).and_return(positive_response)
      service_obj = described_class.create(service_info)
      expect(service_obj.id).to eq('some_id')
      expect(service_obj.remote).to be(remote)
    end
  end

  context 'Service.find' do
    let(:system_name) { random_lowercase_name }
    let(:service_info) { { remote: remote, ref: system_name } }

    it 'remote call raises unexpected error' do
      expect(remote).to receive(:show_service).and_raise(StandardError)
      expect do
        described_class.find(service_info)
      end.to raise_error(StandardError)
    end

    it 'returns nil when the service does not exist' do
      expect(remote).to receive(:show_service).and_raise(ThreeScale::API::HttpClient::NotFoundError)
      expect(remote).to receive(:list_services).and_return([{"system_name" => "sysname1"}, {"system_name" => "sysname2"}])
      expect(described_class.find(service_info)).to be_nil
    end

    it 'service instance is returned when specifying an existing service ID' do
      expect(remote).to receive(:show_service).and_return({"id" => system_name, "system_name" => "sysname1"})
      service_obj = described_class.find(service_info)
      expect(service_obj.id).to eq(system_name)
      expect(service_obj.remote).to be(remote)
    end

    it 'service instance is returned when specifying an existing system-name' do
      expect(remote).to receive(:show_service).and_raise(ThreeScale::API::HttpClient::NotFoundError)
      expect(remote).to receive(:list_services).and_return([{"id" => 3, "system_name" => system_name}, {"id" => 7, "system_name" => "sysname1"}])
      service_obj = described_class.find(service_info)
      expect(service_obj.id).to eq(3)
      expect(service_obj.remote).to be(remote)
    end

    it 'service instance is returned from service ID in front of an existing service with the same system-name as the ID' do
      svc_info = { remote: remote, ref: "3"}
      expect(remote).to receive(:show_service).and_return({"id" => svc_info[:ref], "system_name" => "sysname1"})
      allow(remote).to receive(:list_services).and_return([{"id" => "4", "system_name" => svc_info[:ref]}, {"id" => "5", "system_name" => "sysname2"}])
      service_obj = described_class.find(svc_info)
      expect(service_obj.id).to eq(svc_info[:ref])
      expect(service_obj.remote).to be(remote)
    end
  end

  context 'Service.find_by_system_name' do
    let(:system_name) { random_lowercase_name }
    let(:service_info) { { remote: remote, system_name: system_name } }

    it 'an exception is raised when remote is not configured' do
      expect(remote).to receive(:list_services).and_raise(StandardError)
      expect do
        described_class.find_by_system_name(service_info)
      end.to raise_error(StandardError)
    end

    it 'returns nil when the service does not exist' do
      expect(remote).to receive(:list_services).and_return([{"system_name" => "sysname1"}, {"system_name" => "sysname2"}])
      expect(described_class.find_by_system_name(service_info)).to be_nil
    end

    it 'service instance is returned when specifying an existing system-name' do
      expect(remote).to receive(:list_services).and_return([{"id" => 3, "system_name" => system_name}, {"id" => 7, "system_name" => "sysname1"}])
      service_obj = described_class.find_by_system_name(service_info)
      expect(service_obj.id).to eq(3)
      expect(service_obj.remote).to be(remote)
    end
  end

  context 'instance method' do
    let(:id) { 774 }
    let(:hits_metric) { { 'id' => 1, 'system_name' => 'hits' } }
    let(:metrics) do
      [
        { 'id' => 10, 'system_name' => 'metric_10' },
        hits_metric,
        { 'id' => 20, 'system_name' => 'metric_20' }
      ]
    end
    subject { described_class.new(id: id, remote: remote) }

    context '#show_service' do
      it 'calls show_service method' do
        expect(remote).to receive(:show_service).with(id)
        subject.show_service
      end
    end

    context '#update_proxy' do
      let(:proxy) { { param: 'value' } }

      it 'calls update_proxy method' do
        expect(remote).to receive(:update_proxy).with(id, proxy)
        subject.update_proxy(proxy)
      end
    end

    context '#show_proxy' do
      it 'calls show_proxy method' do
        expect(remote).to receive(:show_proxy).with(id)
        subject.show_proxy
      end
    end

    context '#metrics' do
      it 'calls list_metrics method' do
        expect(remote).to receive(:list_metrics).with(id)
        subject.metrics
      end
    end

    context '#hits' do
      it 'raises error if metric not found' do
        expect(remote).to receive(:list_metrics).with(id).and_return([])
        expect { subject.hits }.to raise_error(ThreeScaleToolbox::Error, /missing hits metric/)
      end

      it 'return hits metric' do
        expect(remote).to receive(:list_metrics).with(id).and_return(metrics)
        expect(subject.hits).to be(hits_metric)
      end
    end

    context '#methods' do
      it 'calls list_methods method' do
        expect(remote).to receive(:list_metrics).with(id).and_return(metrics)
        expect(remote).to receive(:list_methods).with(id, hits_metric['id'])
        subject.methods
      end
    end

    context '#create_metric' do
      it 'calls create_metric method' do
        expect(remote).to receive(:create_metric).with(id, hits_metric)
        subject.create_metric(hits_metric)
      end
    end

    context '#create_method' do
      let(:some_method) { { 'id': 5 } }
      let(:parent_metric_id) { 43 }

      it 'calls create_method method' do
        expect(remote).to receive(:create_method).with(id, parent_metric_id, some_method)
        subject.create_method(parent_metric_id, some_method)
      end
    end

    context '#plans' do
      it 'calls list_service_application_plans method' do
        expect(remote).to receive(:list_service_application_plans).with(id)
        subject.plans
      end
    end

    context '#mapping_rules' do
      it 'calls list_mapping_rules method' do
        expect(remote).to receive(:list_mapping_rules).with(id)
        subject.mapping_rules
      end
    end

    context '#delete_mapping_rule' do
      let(:rule_id) { 3 }
      it 'calls delete_mapping_rule method' do
        expect(remote).to receive(:delete_mapping_rule).with(id, rule_id)
        subject.delete_mapping_rule(rule_id)
      end
    end

    context '#create_mapping_rule' do
      let(:mapping_rule) { { 'id' => 5 } }
      it 'calls create_mapping_rule method' do
        expect(remote).to receive(:create_mapping_rule).with(id, mapping_rule)
        subject.create_mapping_rule(mapping_rule)
      end
    end

    context '#update_service' do
      let(:params) { { 'id' => 5 } }
      it 'calls update_service method' do
        expect(remote).to receive(:update_service).with(id, params)
        subject.update_service(params)
      end
    end

    context '#policies' do
      it 'calls show_policies method' do
        expect(remote).to receive(:show_policies).with(id)
        subject.policies
      end
    end

    context '#update_policies' do
      let(:params) { [] }
      it 'calls update_policies method' do
        expect(remote).to receive(:update_policies).with(id, params)
        subject.update_policies(params)
      end
    end

    context '#list_activedocs' do
      let(:owned_activedocs0) do
        {
          'id' => 0, 'name' => 'ad_0', 'system_name' => 'ad_0', 'service_id' => id
        }
      end
      let(:owned_activedocs1) do
        {
          'id' => 1, 'name' => 'ad_1', 'system_name' => 'ad_1', 'service_id' => id
        }
      end
      let(:not_owned_activedocs) do
        {
          'id' => 2, 'name' => 'ad_2', 'system_name' => 'ad_2', 'service_id' => 'other'
        }
      end
      let(:activedocs) { [owned_activedocs0, owned_activedocs1, not_owned_activedocs] }

      it 'filters activedocs not owned by service' do
        expect(remote).to receive(:list_activedocs).and_return(activedocs)
        expect(subject.list_activedocs).to match_array([owned_activedocs0, owned_activedocs1])
      end
    end

    context 'oidc' do
      let(:oidc_configuration) do
        {
          standard_flow_enabled: false,
          implicit_flow_enabled: true,
          service_accounts_enabled: false,
          direct_access_grants_enabled: false
        }
      end

      context '#show_oidc' do
        it 'calls show_oidc method' do
          expect(remote).to receive(:show_oidc).with(id).and_return(oidc_configuration)
          expect(subject.show_oidc).to eq(oidc_configuration)
        end
      end

      context '#update_oidc' do
        it 'calls update_oidc method' do
          expect(remote).to receive(:update_oidc).with(id, oidc_configuration)
          subject.update_oidc(oidc_configuration)
        end
      end
    end
  end
end
