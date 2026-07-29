module Foobara
  module CommandPatternImplementation
    module Concerns
      module EntityInputs
        include Concern

        module ClassMethods
          def inputs_association_paths
            return @inputs_association_paths if defined?(@inputs_association_paths)

            @inputs_association_paths = if inputs_type.nil?
                                          nil
                                        else
                                          keys = Entity.construct_associations(inputs_type).keys

                                          if keys.empty?
                                            nil
                                          else
                                            keys.map do |key|
                                              DataPath.new(key)
                                            end
                                          end
                                        end
          end

          def skip_model_to_attributes_conversion?(type)
            super || type.extends?(BuiltinTypes[:entity])
          end
        end
      end
    end
  end
end
