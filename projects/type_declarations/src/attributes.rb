module Foobara
  module TypeDeclarations
    module Attributes
      class << self
        def merge(*type_declarations)
          element_type_declarations = {}
          required = []
          defaults = {}

          type_declarations.each do |declaration_data|
            element_type_declarations.merge!(declaration_data[:element_type_declarations])
            type_defaults = declaration_data[:defaults]
            type_required = declaration_data[:required]

            if type_defaults && !type_defaults.empty?
              defaults.merge!(type_defaults)
            end

            if type_required && !type_required.empty?
              required += type_required
            end
          end

          {
            type: "::attributes",
            element_type_declarations:,
            required:,
            defaults:
          }
        end
      end
    end
  end
end
