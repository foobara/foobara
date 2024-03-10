module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class Defaults < Value::Transformer
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def transform(attributes_hash)
            to_apply = {}

            defaults.each_pair do |attribute_name, default|
              if attributes_hash.key?(attribute_name)
                value = attributes_hash[attribute_name]

                if value.nil?
                  allow_nil = parent_declaration_data[:element_type_declarations][attribute_name][:allow_nil]

                  unless allow_nil
                    to_apply[attribute_name] = default
                  end
                end
              else
                to_apply[attribute_name] = default
              end
            end

            if to_apply.empty?
              attributes_hash
            else
              attributes_hash.merge(to_apply)
            end
          end
        end
      end
    end
  end
end
