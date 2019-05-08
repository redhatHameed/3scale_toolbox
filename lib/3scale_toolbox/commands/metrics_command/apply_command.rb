module ThreeScaleToolbox
  module Commands
    module MetricsCommand
      module Apply
        class ApplySubcommand < Cri::CommandRunner
          include ThreeScaleToolbox::Command

          def self.command
            Cri::Command.define do
              name        'apply'
              usage       'apply [opts] <remote> <service> <metric>'
              summary     'Update metric'
              description 'Update (create if it does not exist) metric'

              option      :n, :name, 'Metric name', argument: :required
              flag        nil, :disabled, 'Disables this metric in all application plans'
              flag        nil, :enabled, 'Enables this metric in all application plans'
              option      nil, :unit, 'Metric unit. Default hit', argument: :required
              option      nil, :description, 'Metric description', argument: :required
              param       :remote
              param       :service_ref
              param       :metric_ref

              runner ApplySubcommand
            end
          end

          def run
            validate_option_params
            metric = Entities::Metric.find(service: service, ref: metric_ref)
            if metric.nil?
              metric = Entities::Metric.create(service: service,
                                               attrs: create_metric_attrs)
            else
              metric.update(metric_attrs) unless metric_attrs.empty?
            end

            metric.disable if option_disabled
            metric.enable if option_enabled

            output_msg_array = ["Applied metric id: #{metric.id}"]
            output_msg_array << 'Disabled' if option_disabled
            output_msg_array << 'Enabled' if option_enabled
            puts output_msg_array.join('; ')
          end

          private

          def validate_option_params
            raise ThreeScaleToolbox::Error, '--disabled and --enabled are mutually exclusive' \
              if option_enabled && option_disabled
          end

          def create_metric_attrs
            metric_attrs.merge('system_name' => metric_ref,
                               'friendly_name' => metric_ref) { |_key, oldval, _newval| oldval }
          end

          def metric_attrs
            {
              'friendly_name' => options[:name],
              'unit' => options[:unit],
              'description' => options[:description]
            }.compact
          end

          def option_enabled
            !options[:enabled].nil?
          end

          def option_disabled
            !options[:disabled].nil?
          end

          def service
            @service ||= find_service
          end

          def find_service
            Entities::Service.find(remote: remote,
                                   ref: service_ref).tap do |svc|
              raise ThreeScaleToolbox::Error, "Service #{service_ref} does not exist" if svc.nil?
            end
          end

          def remote
            @remote ||= threescale_client(arguments[:remote])
          end

          def service_ref
            arguments[:service_ref]
          end

          def metric_ref
            arguments[:metric_ref]
          end
        end
      end
    end
  end
end
