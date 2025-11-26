module Foobara
  class DetachedEntity < Model
    class NoCurrentTransactionError < StandardError; end

    module Concerns
      module Initialization
        include Concern

        module ClassMethods
          def unloaded(primary_key_value)
            primary_key_value = primary_key_type.process_value!(primary_key_value)

            new({ primary_key_attribute => primary_key_value }, unloaded: true)
          end
        end

        ALLOWED_OPTIONS = Model::ALLOWED_OPTIONS + [:unloaded]

        def initialize(attributes = nil, options = {})
          invalid_options = options.keys - ALLOWED_OPTIONS

          unless invalid_options.empty?
            # :nocov:
            raise ArgumentError, "Invalid options #{invalid_options} expected only #{ALLOWED_OPTIONS}"
            # :nocov:
          end

          if options[:unloaded]
            options = options.except(:unloaded)

            unless options.key?(:validate)
              options[:validate] = false
            end

            unless options.key?(:skip_validations)
              options[:skip_validations] = true
            end

            unless options.key?(:ignore_unexpected_attributes)
              options[:ignore_unexpected_attributes] = false
            end

            unless options.key?(:mutable)
              options[:mutable] = false
            end

            super
            self.is_loaded = false
          else
            super
            self.is_loaded = true
          end
        end
      end
    end
  end
end
