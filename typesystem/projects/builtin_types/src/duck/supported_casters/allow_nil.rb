module Foobara
  module BuiltinTypes
    module Duck
      module SupportedCasters
        class AllowNil < TypeDeclarations::Caster
          class << self
            def requires_declaration_data?
              true
            end

            def default_declaration_data
              false
            end
          end

          def applicable?(value)
            value.nil? && allow_nil?
          end

          def allow_nil?
            declaration_data
          end

          def cast(value)
            value
          end

          def applies_message
            "be nil"
          end

          def priority
            Priority::HIGH
          end
        end
      end
    end
  end
end
