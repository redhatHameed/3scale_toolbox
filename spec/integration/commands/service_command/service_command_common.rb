require '3scale_toolbox'

RSpec.shared_context :service_command_real_api3scale_client do
  include_context :real_api3scale_client
  let(:remote) do
    endpoint_uri = URI(endpoint)
    endpoint_uri.user = provider_key
    endpoint_uri.to_s
  end
end

RSpec.shared_context :service_command_mock_api3scale_client do
  let(:internal_http_client) { double('internal_http_client') }
  let(:http_client_class) { class_double('ThreeScale::API::HttpClient').as_stubbed_const }
  let(:external_http_client) { double('external_http_client') }
  let(:api3scale_client) { ThreeScale::API::Client.new(external_http_client) }

  let(:remote) { "https://example-remote.com" }

  before :example do
    puts '============ RUNNING STUBBED 3SCALE API CLIENT =========='
    ##
    # Internal http client stub
    allow(http_client_class).to receive(:new).and_return(internal_http_client)
  end
end

RSpec.shared_context :create_command_api3scale_client do
  if ENV.key?('ENDPOINT')
    include_context :service_command_real_api3scale_client
  else
    include_context :service_command_mock_api3scale_client
  end
end