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

          handler = Domain.global.foobara_type_builder.handler_for_class(
            TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
          )

          declaration = TypeDeclaration.new(
            type: :attributes,
            element_type_declarations:,
            required:,
            defaults:
          )
          declaration.is_absolutified = true
          declaration.is_duped = true

          handler.desugarize(declaration).declaration_data
        end

        def only(declaration, *keys)
          valid_keys = declaration[:element_type_declarations].keys
          keys_to_keep = keys.map(&:to_sym)
          invalid_keys = keys_to_keep - valid_keys

          if invalid_keys.any?
            # :nocov:
            raise ArgumentError, "Invalid keys: #{invalid_keys} expected only #{valid_keys}"
            # :nocov:
          end

          keys_to_reject = valid_keys - keys_to_keep

          reject(declaration, keys_to_reject)
        end

        def reject(declaration_data, *keys)
          declaration = TypeDeclaration.new(declaration_data)

          element_type_declarations = declaration[:element_type_declarations]
          required = declaration[:required]
          defaults = declaration[:defaults]

          changed = false

          keys.flatten.each do |key|
            key = key.to_sym

            if element_type_declarations.key?(key)
              changed = true
              declaration[:element_type_declarations] = declaration[:element_type_declarations].except(key)
            end

            if required&.include?(key)
              changed = true
              required = required.dup
              required.delete(key)
              declaration[:required] = required
            end

            if defaults&.key?(key)
              changed = true
              defaults = defaults.except(key)
              declaration[:defaults] = defaults
            end
          end

          if changed
            handler = Domain.global.foobara_type_builder.handler_for_class(
              TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration
            )

            handler.desugarize(declaration).declaration_data
          else
            declaration_data
          end
        end
      end
    end
  end
end
