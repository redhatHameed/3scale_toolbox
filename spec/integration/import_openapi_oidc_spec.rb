require '3scale_toolbox'

RSpec.shared_context :import_oas_oidc_stubbed do
  include_context :oas_common_mocked_context

  let(:external_proxy) do
    {
      'proxy' => {
        'service_id' => fake_service_id,
        'endpoint' => 'https://production.gw.apicast.io:443',
        'sandbox_endpoint' => 'https://staging.gw.apicast.io:443',
        'api_backend' => 'https://echo-api.3scale.net:443',
        'credentials_location' => 'headers',
        'auth_app_key' => 'app_key',
        'auth_app_id' => 'app_id',
        'oidc_issuer_endpoint' => 'https://issuer.com',
        'auth_user_key' => 'api_key'
      }
    }
  end
end

RSpec.describe 'OpenAPI import OIDC service' do
  include_context :oas_common_context
  include_context :import_oas_oidc_stubbed unless ENV.key?('ENDPOINT')

  # render from template to avoid system_name collision
  let(:oas_resource_path) { File.join(resources_path, 'oidc.yaml') }
  let(:issuer_endpoint) { 'https://issuer.com' }
  let(:command_line_str) do
    "import openapi -t #{system_name} --oidc-issuer-endpoint=#{issuer_endpoint} " \
    " -d #{destination_url} #{oas_resource_path}"
  end
  let(:backend_version) { 'oidc' }
  let(:credentials_location) { 'headers' }

  it 'oidc settings are updated' do
    expect { subject }.to output.to_stdout
    expect(subject).to eq(0)
    expect(service_settings).not_to be_nil
    expect(service_settings).to include('backend_version' => backend_version)
    expect(service_proxy).not_to be_nil
    expect(service_proxy).to include('oidc_issuer_endpoint' => issuer_endpoint,
                                     'credentials_location' => credentials_location)
  end
end
