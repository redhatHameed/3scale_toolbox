module ThreeScaleToolbox
  module Commands
    class ServiceListCommand < Cri::CommandRunner
      include ThreeScaleToolbox::Command

      def self.command
        Cri::Command.define do
          name        'service_list'
          usage       'service_list <3scale_remote>'
          summary     '3scale CLI service list'
          description '3scale CLI command to list services'
          param       :remote
          runner ServiceListCommand
        end
      end

      def run
        puts threescale_client(arguments[:remote]).list_services
      end
    end
  end
end
