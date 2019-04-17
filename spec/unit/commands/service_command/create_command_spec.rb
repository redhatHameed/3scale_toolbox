 require '3scale_toolbox'

RSpec.describe ThreeScaleToolbox::Commands::ServiceCommand::ServiceCreateSubcommand do
  include_context :random_name

  context '#run' do
    let(:remote) { double('remote') }
    let(:options) { {} }

    subject { described_class.new(options, arguments, nil) }

    before :example do
      expect(subject).to receive(:threescale_client).with('myremote').and_return(remote)
    end

    # This should cover the case where the service already exists
    # or other errors that are returned by calls to the API
    context "when there is an error creating the service" do
      let(:arguments) { {remote: "myremote", service_name: "existingservice"} }
      let(:exists_error_response) { { 'errors' => { 'system_name' => ["has already been taken"] } } }

      it 'an error is raised' do
        expect(remote).to receive(:create_service).and_return(exists_error_response)
        expect do
          subject.run
        end.to raise_error(ThreeScaleToolbox::Error, /Service has not been saved/)
      end
    end

    context "service name parameter is specified" do
      let(:arguments) { {remote: "myremote", service_name: service_name} }
      let(:service_name) { "a_service_name" }
      let(:service_create_args) { {"name" => service_name} }
      let(:service_create_result) { {"name" => service_name, "system_name" => service_name, "id" => "1" } }

      before :example do
        expect(remote).to receive(:create_service).with(service_create_args).and_return(service_create_result)
      end

      shared_examples "successfully creates the service with it" do
        it do
          expect do
            subject.run
          end.to output(/Service '#{service_name}' has been created with ID: #{service_create_result['id']}/).to_stdout
        end
      end

      include_examples "successfully creates the service with it"

      context "and additional options are specified" do
        context "specifying system_name option" do
          let(:system_name) { "a_system_name" }
          let(:options) { { :'system-name' => system_name } }
          let(:service_create_args) { {"name" => service_name, "system_name" => system_name } }
          let(:service_create_result) { {"name" => service_name, "system_name" => system_name, "id" => "1" } }
          include_examples "successfully creates the service with it"
        end

        context "specifying authentication-mode option" do
          let(:authentication_mode) { "1" }
          let(:options) { { :'authentication-mode' => authentication_mode } }
          let(:service_create_args) { {"name" => service_name, "backend_version" => authentication_mode } }
          let(:service_create_result) { {"name" => service_name, "system_name" => service_name, "id" => "1", "backend_version" => authentication_mode } }
          include_examples "successfully creates the service with it"
        end

        context "specifying an invalid deployment option" do
          let(:deployment_mode) { "invaliddeploymentoption" }
          let(:options) { { :'deployment-mode' => deployment_mode } }
          let(:original_service_create_args) { {"name" => service_name, "deployment_option" => deployment_mode } }
          let(:service_create_args) { {"name" => service_name} }
          let(:service_create_result) { {"name" => service_name, "system_name" => service_name, "id" => "1" } }
          let(:invalid_deployment_error) { {"errors"=>{"deployment_option"=>["is not included in the list"]}} }

          before :example do
            expect(remote).to receive(:create_service).with(original_service_create_args).and_return(invalid_deployment_error)
          end
          include_examples "successfully creates the service with it"
        end

        context "specifying a valid deployment option" do
          let(:deployment_mode) { "valid_deploymentoption" }
          let(:options) { { :'deployment-mode' => deployment_mode } }
          let(:service_create_args) { {"name" => service_name, "deployment_option" => deployment_mode } }
          let(:service_create_result) { {"name" => service_name, "system_name" => service_name, "id" => "1" } }
          include_examples "successfully creates the service with it"
        end
      end
    end
  end
end