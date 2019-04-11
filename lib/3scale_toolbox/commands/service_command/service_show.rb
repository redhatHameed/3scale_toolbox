module ThreeScaleToolbox
  module Commands
    module ServiceCommand
      class ServiceShowSubcommand < Cri::CommandRunner
        include ThreeScaleToolbox::Command

        def self.command
          Cri::Command.define do
            name        'show'
            usage       'show'
            summary     'service show <remote> <service-id_or_system-name>'
            description "Show the information of a service"
            runner ServiceShowSubcommand

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
          print_service_data(service, SERVICE_FIELDS_TO_SHOW)
        end

        private

        SERVICE_FIELDS_TO_SHOW = %w[
          id name state system_name end_user_registration_required
          backend_version deployment_option support_email description
          created_at updated_at
        ]

        def print_service_data(service, fields_to_show)
          print_header(fields_to_show)
          print_results(service, fields_to_show)
        end

        def print_header(fields)
          puts fields.map{ |e| e.upcase}.join("\t")
        end

        def print_results(service, fields)
          ordered_results = []
          service_data = service.show_service
          fields.each do |field|
            result = service_data.fetch(field, "nil")
            if result.to_s.empty?
              result = "(empty)"
            end
            ordered_results << result
          end
          puts ordered_results.join("\t")
        end
      end
    end
  end
end
