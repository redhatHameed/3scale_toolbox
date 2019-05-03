module ThreeScaleToolbox
  module Entities
    class Metric
      class << self
        def create(service:, attrs:)
          metric = service.create_metric attrs
          new(id: metric.fetch('id'), service: service)
        end

        # ref can be system_name or service_id
        def find(service:, ref:)
          metric = service.metrics.find { |m| [m['system_name'], m['id']].include? ref }
          return if metric.nil?

          new(id: metric.fetch('id'), service: service)
        end
      end

      attr_reader :id, :service, :remote

      def initialize(id:, service:)
        @id = id
        @service = service
        @remote = service.remote
      end

      def disable
        # For each plan, get limits for the current metric
        # if already disabled -> NOOP
        # if non zero eternity limit exist, update
        # if non eternity limit exist, create
        service_plans.each do |plan|
          eternity_limit = plan_eternity_limit(plan)
          if eternity_limit.nil?
            plan.create_limit(id, zero_eternity_limit_attrs)
          elsif !eternity_limit.fetch('value').zero?
            plan.update_limit(id, eternity_limit.fetch('id'), zero_eternity_limit_attrs)
          end
        end
      end

      def enable
        service_plans.each do |plan|
          limit = plan_zero_eternity_limit(plan)
          plan.delete_limit(id, limit.fetch('id')) unless limit.nil?
        end
      end

      def update(metric_attrs)
        metric = remote.update_metric(service.id, id, metric_attrs)
        if (errors = metric['errors'])
          raise ThreeScaleToolbox::Error, "Metric has not been updated. Errors: #{errors}"
        end

        metric
      end

      def delete
        remote.delete_metric service.id, id
      end

      private

      def plan_zero_eternity_limit(plan)
        # only one limit for eternity period is allowed per (plan_id, metric_id)
        plan.metric_limits(id).find { |limit| limit > zero_eternity_limit_attrs }
      end

      def plan_eternity_limit(plan)
        # only one limit for eternity period is allowed per (plan_id, metric_id)
        plan.metric_limits(id).find { |limit| limit['period'] == 'eternity' }
      end

      def service_plans
        service.plans.map do |plan_attrs|
          ThreeScaleToolbox::Entities::ApplicationPlan.new(id: plan_attrs.fetch('id'),
                                                           service: service)
        end
      end

      def zero_eternity_limit_attrs
        { 'period' => 'eternity', 'value' => 0 }
      end
    end
  end
end
