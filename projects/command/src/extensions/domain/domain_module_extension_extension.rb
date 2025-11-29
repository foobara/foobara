# rubocop:disable Naming/FileName
module Foobara
  class Command
    module DomainModuleExtensionExtension
      module ClassMethods
        def foobara_manifest
          to_include = TypeDeclarations.foobara_manifest_context_to_include

          commands = foobara_all_command(mode: Namespace::LookupMode::DIRECT).map do |command_class|
            if to_include
              to_include << command_class
            end
            command_class.foobara_manifest_reference
          end.sort

          super.merge(commands:)
        end
      end
    end
  end
end
# rubocop:enable Naming/FileName
