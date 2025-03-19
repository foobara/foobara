module Foobara
  module Types
    class Type < Value::Processor::Pipeline
      module Concerns
        module Reflection
          include Concern

          # as soon as we hit a registered type, don't go further down that path
          def types_depended_on(result = nil, remove_sensitive: false)
            start = result.nil?
            result ||= Set.new
            return if result.include?(self)

            result << self

            return if !start && registered?

            to_process = types_to_add_to_manifest(remove_sensitive:)

            if element_types
              to_process += case element_types
                            when Type
                              if remove_sensitive && element_types.sensitive?
                                # TODO: test this code path
                                # :nocov:
                                []
                                # :nocov:
                              else
                                [element_types]
                              end
                            when ::Hash
                              element_types.values.select do |value|
                                if !remove_sensitive || !value.sensitive?
                                  value.is_a?(Type)
                                end
                              end
                            when ::Array
                              if remove_sensitive
                                element_types.reject(&:sensitive?)
                              else
                                element_types
                              end
                            else
                              # :nocov:
                              raise "Not sure how to find dependent types for #{element_types}"
                              # :nocov:
                            end
            end

            to_process.each do |type|
              type.types_depended_on(result, remove_sensitive:)
            end

            if start
              result = result.select { |type| type.registered? && type != self }.to_set
            end

            result
          end

          def types_to_add_to_manifest(remove_sensitive: false)
            types = [*base_type, *possible_errors.map(&:error_class)]

            if element_type && (!remove_sensitive || !element_type.sensitive?)
              types << element_type
            end

            types
          end

          def deep_types_depended_on
            result = Set.new
            to_process = types_depended_on

            until to_process.empty?
              type = to_process.first
              to_process.delete(type)

              next if result.include?(type)

              result << type

              to_process |= type.types_depended_on
            end

            result.select(&:registered?)
          end

          def inspect
            # :nocov:
            name = if scoped_path_set?
                     scoped_full_name
                   else
                     "Anonymous #{base_type.type_symbol}"
                   end

            "#<Type:#{name}:0x#{object_id.to_s(16)} #{declaration_data}>"
            # :nocov:
          end
        end
      end
    end
  end
end
