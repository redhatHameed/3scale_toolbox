module ThreeScaleToolbox
  module Commands
    module CopyCommand
      class CopyServiceSubcommand < Cri::CommandRunner
        include ThreeScaleToolbox::Command

        def self.command
          Cri::Command.define do
            name        'service'
            usage       'service [opts] -s <src> -d <dst> <service_id>'
            summary     'copy service'
            description 'will create a new services, copy existing proxy settings, metrics, methods, application plans and mapping rules.'

            option  :s, :source, '3scale source instance. Url or remote name', argument: :required
            option  :d, :destination, '3scale target instance. Url or remote name', argument: :required
            option  :t, 'target_system_name', 'Target system name. Default to source system name', argument: :required
            param   :service_id

            runner CopyServiceSubcommand
          end
        end

        def run
          source      = fetch_required_option(:source)
          destination = fetch_required_option(:destination)

          source_service = Entities::Service.new(id: arguments[:service_id],
                                                 remote: threescale_client(source))
          dest_service_params = source_service.show_service
          dest_service_params["system_name"] = options[:target_system_name] if !options[:target_system_name].nil?
          target_service = create_new_service(dest_service_params, destination)
          puts "new service id #{target_service.id}"
          context = create_context(source_service, target_service)
          tasks = [
            Tasks::CopyMethodsTask.new(context),
            Tasks::CopyMetricsTask.new(context),
            Tasks::CopyApplicationPlansTask.new(context),
            Tasks::CopyLimitsTask.new(context),
            Tasks::DestroyMappingRulesTask.new(context),
            Tasks::CopyMappingRulesTask.new(context),
            Tasks::CopyPoliciesTask.new(context),
            Tasks::CopyPricingRulesTask.new(context),
            Tasks::CopyActiveDocsTask.new(context),
            # Copy proxy must be the last task
            # Proxy update is the mechanism to increase version of the proxy,
            # Hence propagating (mapping rules, poicies, oidc, auth) update to
            # latest proxy config, making available to gateway.
            Tasks::CopyServiceProxyTask.new(context),
          ]
          tasks.each(&:call)
        end

        private

        def create_context(source, target)
          {
            source: source,
            target: target
          }
        end

        def create_new_service(service, destination)
          Entities::Service.create(remote: threescale_client(destination),
                                   service_params: service)
        end
      end
    end
  end
end
