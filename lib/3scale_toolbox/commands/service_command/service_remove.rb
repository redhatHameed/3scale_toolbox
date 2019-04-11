module ThreeScaleToolbox
  module Commands
    module ServiceCommand
      class ServiceRemoveSubcommand < Cri::CommandRunner
        include ThreeScaleToolbox::Command

        def self.command
          Cri::Command.define do
            name        'remove'
            usage       'remove'
            summary     'service remove <remote> <service-id_or_system-name>'
            description 'Remove a service'
            runner ServiceRemoveSubcommand

            param   :remote
            param   :service_id_or_system_name
          end
        end

        def run
          remote = arguments[:remote]
          service_id_or_system_name = arguments[:service_id_or_system_name]
          client = threescale_client(remote)

          service = Entities::Service::find(remote: client, ref: service_id_or_system_name)
          if !service
            raise ThreeScaleToolbox::Error, "Service #{service_id_or_system_name} not found"
          end
          service.delete_service
          puts "Service with #{service_id_or_system_name} removed"
        end
      end
    end
  end
end