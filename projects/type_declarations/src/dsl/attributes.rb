module Foobara
  module TypeDeclarations
    module Dsl
      # NOTE: when debugging stuff, it's helpful to comment out the inheritance from BasicObject
      class Attributes < BasicObject
        class << self
          def to_declaration(&)
            new._to_declaration(&)
          end
        end

        attr_accessor :_method_missing_disabled

        def _to_declaration(&)
          instance_eval(&)
          _prune_type_declaration
          _type_declaration
        end

        def method_missing(attribute_name, *processor_symbols, **declaration, &block)
          unless respond_to_missing?(attribute_name)
            # :nocov:
            return super
            # :nocov:
          end

          _disable_method_missing do
            declaration = declaration.dup

            # if block_given?
            # declaration = self.class.to_declaration(&).merge(declaration)
            unless block
              type, *processor_symbols = processor_symbols
            end

            processor_symbols.each do |processor_symbol|
              unless processor_symbol.is_a?(::Symbol)
                # :nocov:
                raise ArgumentError, "expected a Symbol, got #{processor_symbol.inspect}"
                # :nocov:
              end

              declaration[processor_symbol] = true
            end

            if declaration.delete(:required)
              _add_to_required(attribute_name)
            end

            default = declaration.delete(:default)

            if default
              _add_to_defaults(attribute_name, default)
            end

            if declaration.empty? && !block
              _add_attribute(attribute_name, type)
            else
              declaration = if block
                              Attributes.to_declaration(&block).merge(declaration)
                            else
                              declaration.merge(type:)
                            end

              _add_attribute(attribute_name, declaration)
            end

            _type_declaration
          end
        end

        def respond_to_missing?(method_name, private = false)
          !_method_missing_disabled || super
        end

        private

        def _disable_method_missing
          old = _method_missing_disabled

          begin
            self._method_missing_disabled = true
            yield
          ensure
            self._method_missing_disabled = old
          end
        end

        def _add_attribute(attribute_name, declaration)
          _type_declaration[:element_type_declarations][attribute_name.to_sym] = declaration
        end

        def _add_to_required(attribute_name)
          _type_declaration[:required] << attribute_name.to_sym
        end

        def _add_to_defaults(attribute_name, value)
          _type_declaration[:defaults][attribute_name.to_sym] = value
        end

        def _prune_type_declaration
          if _type_declaration[:required].empty?
            _type_declaration.delete(:required)
          end

          if _type_declaration[:defaults].empty?
            _type_declaration.delete(:defaults)
          end
        end

        def _type_declaration
          @_type_declaration ||= {
            type: :attributes,
            element_type_declarations: {},
            required: [],
            defaults: {}
          }
        end
      end
    end
  end
end
