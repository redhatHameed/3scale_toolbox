require '3scale_toolbox'

RSpec.describe ThreeScaleToolbox::Commands::ServiceCommand::ServiceRemoveSubcommand do
  include_context :random_name

  context '#run' do
    let(:remote) { double('remote') }
    let(:options) {}

    subject { described_class.new(options, arguments, nil) }

    before :example do
      expect(subject).to receive(:threescale_client).with('myremote').and_return(remote)
    end

    context "when the service does not exists" do
      let(:arguments) { {remote: "myremote", service_id_or_system_name: "unexistingservice" } }

      it 'an error is raised' do
        expect(remote).to receive(:show_service).and_raise(ThreeScale::API::HttpClient::NotFoundError)
        expect(remote).to receive(:list_services).and_return([])
        expect do
          subject.run
        end.to raise_error(ThreeScaleToolbox::Error, /Service.*not found/)
      end
    end

    context "when a service exists" do
      let(:existing_service) { {"id" => "1", "system_name" => "existingservice", "name" => "name1"} }
      let(:arguments) { {remote: "myremote", service_id_or_system_name: existing_service["id"]} }

      it 'is removed' do
        expect(remote).to receive(:show_service).with(existing_service["id"]).and_return(existing_service)
        expect(remote).to receive(:delete_service).with(existing_service["id"])
        subject.run
      end
    end
  end
end