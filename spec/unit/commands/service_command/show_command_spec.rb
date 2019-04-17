require '3scale_toolbox'

RSpec.describe ThreeScaleToolbox::Commands::ServiceCommand::ServiceShowSubcommand do
  context '#run' do
    let(:remote) { double('remote') }
    let(:options) {}
    subject { described_class.new(options, arguments, nil) }

    before :example do
      expect(subject).to receive(:threescale_client).with('myremote').and_return(remote)
    end

    context "when the service does not exists" do
      let(:arguments) { {remote: "myremote", service_id_or_system_name: "unexistingservice"} }

      it 'an error is raised' do
        expect(remote).to receive(:show_service).and_raise(ThreeScale::API::HttpClient::NotFoundError)
        expect(remote).to receive(:list_services).and_return([])
        expect do
          subject.run
        end.to raise_error(ThreeScaleToolbox::Error, /Service.*not found/)
      end
    end

    context "when a service exists" do
      let(:existing_service) { {"id" => "1", "system_name" => "existingservice", "name" => "name1", "support_email" => ""} }
      let(:arguments) { {remote: "myremote", service_id_or_system_name: existing_service["id"]} }

      before :example do
        expect(remote).to receive(:show_service).and_return(existing_service).twice()
      end

      it "shows the service fields" do
        regex_str = ".*" + existing_service.fetch("id") +
                    ".*" + existing_service.fetch("name") +
                    ".*" + existing_service.fetch("system_name")
        expect do
          subject.run
        end.to output(/#{regex_str}/).to_stdout
      end

      it "shows non defined fields as nil" do
        expect do
          subject.run
        end.to output(/.*nil.*/).to_stdout
      end

      it "shows empty string fields as (empty)" do
        expect do
          subject.run
        end.to output(/.*\(empty\).*/).to_stdout
      end
    end
  end
end