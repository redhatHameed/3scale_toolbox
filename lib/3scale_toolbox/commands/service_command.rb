require 'cri'
require '3scale_toolbox/base_command'
require '3scale_toolbox/commands/service_command/service_list'
require '3scale_toolbox/commands/service_command/service_show'
require '3scale_toolbox/commands/service_command/service_remove'
require '3scale_toolbox/commands/service_command/service_create'

module ThreeScaleToolbox
  module Commands
    module ServiceCommand
      class ServiceCommand < Cri::CommandRunner
        include ThreeScaleToolbox::Command

        def self.command
          Cri::Command.define do
            name        'service'
            usage       'service <sub-command> [options]'
            summary     'services super command'
            description 'Manage your services'
            runner ServiceCommand
          end
        end

        def run
          puts command.help
        end

        add_subcommand(ServiceListSubcommand)
        add_subcommand(ServiceShowSubcommand)
        add_subcommand(ServiceRemoveSubcommand)
        add_subcommand(ServiceCreateSubcommand)
      end
    end
  end
end
