module ThreeScaleToolbox
  module Commands
    module ServiceCommand
      class ServiceCreateSubcommand < Cri::CommandRunner
        include ThreeScaleToolbox::Command

        def self.command
          Cri::Command.define do
            name        'create'
            usage       'create [options] <remote> <service-name>'
            summary     'service create'
            description 'Create a service'
            runner ServiceCreateSubcommand

            param   :remote
            param   :service_name

            option :d, :'deployment-mode', "Specify the deployment mode of the service", argument: :required
            option :s, :'system-name', "Specify the system-name of the service", argument: :required
            option :a, :'authentication-mode', "Specify authentication mode of the service ('1' for API key, '2' for App Id / App Key, 'oauth' for OAuth mode, 'oidc' for OpenID Connect)", argument: :required
          end
        end

        def run
          remote = arguments[:remote]
          client = threescale_client(remote)
          create_service_params = service_params
          result = Entities::Service.create(remote: client, service_params: create_service_params)
          puts "Service '#{arguments[:service_name]}' has been created with ID: #{result.id}"
        end

        private

        def parse_options
          {
            "deployment_option" => options[:'deployment-mode'],
            "system_name" => options[:'system-name'],
            "backend_version" => options[:'authentication-mode'],
          }.compact
        end

        def service_params
          service_name = arguments[:service_name]
          create_service_params = parse_options
          create_service_params["name"] = service_name
          create_service_params
        end
      end
    end
  end
end