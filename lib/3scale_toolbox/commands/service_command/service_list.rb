module ThreeScaleToolbox
  module Commands
    module ServiceCommand
      class ServiceListSubcommand < Cri::CommandRunner
        include ThreeScaleToolbox::Command

        def self.command
          Cri::Command.define do
            name        'list'
            usage       'list'
            summary     'service list <remote>'
            description 'List all services'
            runner ServiceListSubcommand

            param   :remote
          end
        end

        def run
          remote = arguments[:remote]
          client = threescale_client(remote)
          services = client.list_services()
          result_header = "ID\tNAME\tSYSTEM_NAME"
          puts result_header
          services.each do |service|
            puts "#{service['id']}\t#{service['name']}\t#{service['system_name']}"
          end
        end
      end
    end
  end
end
