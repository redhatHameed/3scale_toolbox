require '3scale_toolbox'
require_relative 'service_command_common'

RSpec.describe 'Service Create command' do
  include_context :create_command_api3scale_client
  subject { ThreeScaleToolbox::CLI.run(command_line_str.split) }

  context 'Successfully creates a new service' do
    let (:service_name) { "service_1" }
    let (:command_line_str) { "service create #{remote} #{service_name}" }
    let (:service_id) { "3" }
    let (:backend_version) { "1" }
    let (:service_attr) do
      { 'service' => { 'id' => service_id,
                       'system_name' => service_name,
                       'backend_version' => backend_version } }
    end
    let (:service_res) do
      {
        "id" => service_id,
        "system_name" => service_id,
        "backend_version" => backend_version,
      }
    end

    RSpec.shared_context :preconfigure_mock_api3scale_client do
      before :example do
        allow(internal_http_client).to receive(:post).with('/admin/api/services', anything)
        .and_return(service_attr)
        allow(external_http_client).to receive(:get).with("/admin/api/services/#{service_id}")
        .and_return(service_res)
      end
    end
    RSpec.shared_context :cleanup_real_create_command do
      after :example do
        api3scale_client.delete_service(:service_id)
      end
    end

    if ENV.key?('ENDPOINT')
      include_context :cleanup_real_create_command
    else
      include_context :preconfigure_mock_api3scale_client
    end

    it do
      expected_regex_result = /.*#{service_name}.*created.*/
      expect { subject }.to output(expected_regex_result).to_stdout
      expect(subject).to eq(0)

      res = api3scale_client.show_service(service_id)
      expect(res).to include(service_res)
    end
  end
end