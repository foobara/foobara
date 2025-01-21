# This is currently the working file, fix this up/move it

module Foobara
  class Entity
    module Concerns
      module AttributeHelperAliases
        include Foobara::Concern

        module ClassMethods
          %i[
            attributes_for_update
            type_from_foobara_model_class
            attributes_type_from_foobara_model_class
            primary_key_attribute_from_foobara_model_class
            foobara_model_class_has_primary_key
            attributes_for_create
            attributes_for_aggregate_update
            attributes_for_atom_update
            attributes_for_find_by
            type_declaration_value_at
          ].each do |method_name|
            define_method method_name do |*args, **opts, &block|
              send("foobara_#{method_name}", *args, **opts, &block)
            end
          end
        end
      end
    end
  end
end
