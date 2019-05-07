require '3scale_toolbox'

RSpec.describe ThreeScaleToolbox::Commands::ServiceCommand::ServiceListSubcommand do
  context '#run' do
    let(:remote) { double('remote') }
    let(:options) {}
    let(:arguments) { {remote: "myremote"} }

    subject { described_class.new(options, arguments, nil) }

    before :example do
      expect(subject).to receive(:threescale_client).with('myremote').and_return(remote)
    end

    it 'when no services are present only the result header is printed' do
      expect(remote).to receive(:list_services).and_return([])
      expect { subject.run }.to output("ID\tNAME\tSYSTEM_NAME\n").to_stdout
    end

    it 'when services are present those are printed' do
      expect(remote).to receive(:list_services).and_return(
        [
          {"id" => 1, "name" => "name1", "system_name" => "sysname1"},
          {"id" => 2, "name" => "name2", "system_name" => "sysname2"},
        ]
      )
      expect { subject.run }.to output("ID\tNAME\tSYSTEM_NAME\n1\tname1\tsysname1\n2\tname2\tsysname2\n").to_stdout
    end
  end
end