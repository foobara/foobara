module Foobara
  module TypeDeclarations
    module Dsl
      class NoTypeGivenError < StandardError; end

      class BadAttributeError < StandardError
        attr_accessor :attribute_name, :method_name

        def initialize(attribute_name, method_name)
          self.attribute_name = attribute_name
          self.method_name = method_name

          super("You probably did not mean to declare an attribute named \"#{attribute_name}\" " \
                "but you tried to access .\"#{method_name}\" method on it. " \
                "Return values of attribute declarations do not return anything meaningful.")
        end
      end

      # Using this class as a proxy to explode if somebody accidentally tries to use the return value of an
      # attribute declaration
      # NOTE: when debugging stuff, it's helpful to comment out the inheritance from BasicObject
      class AttributeCreated < BasicObject
        def initialize(name)
          @_name = name
        end

        def method_missing(method_name, ...)
          ::Kernel.raise BadAttributeError.new(@_name, method_name)
        end

        def respond_to_missing?(...)
          # :nocov:
          false
          # :nocov:
        end
      end

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

            if block
              # TODO: technically, current namespace might have an overridden :array type so instead we
              # should lookup :array he to see if we get BuiltinTypes[:array] or not (or "::array" or not)
              if processor_symbols.first == :array
                type, *processor_symbols = processor_symbols
              end
            else
              type, *processor_symbols = processor_symbols

              unless type
                if processor_symbols.empty? && !declaration.empty?
                  type = :attributes
                  declaration = { element_type_declarations: declaration }
                else
                  ::Kernel.raise NoTypeGivenError, "Expected a type but attribute #{attribute_name} was declared " \
                                                   "without a type. (Perhaps you didn't mean for #{attribute_name} " \
                                                   "to be an attribute?)"
                end
              end
            end

            processor_symbols.each do |processor_symbol|
              case processor_symbol
              when ::String
                description = processor_symbol

                if declaration.key?(:description)
                  # :nocov:
                  ::Kernel.raise ArgumentError, "Expected only one description but " \
                                                "got #{description.inspect} and #{declaration[:description].inspect}"
                  # :nocov:
                end

                declaration[:description] = description
              when ::Symbol
                declaration[processor_symbol] = true
              else
                # :nocov:
                ::Kernel.raise ArgumentError, "expected a Symbol, got #{processor_symbol.inspect}"
                # :nocov:
              end
            end

            if declaration.delete(:required)
              _add_to_required(attribute_name)
            end

            if declaration.key?(:default)
              default = declaration.delete(:default)

              _add_to_defaults(attribute_name, default)
            end

            if declaration.empty? && !block
              _add_attribute(attribute_name, type)
            else
              declaration = if block
                              attributes_declaration = Attributes.to_declaration(&block).merge(declaration)

                              if type == :array
                                {
                                  type: :array,
                                  element_type_declaration: attributes_declaration
                                }
                              else
                                attributes_declaration
                              end
                            else
                              declaration.merge(type:)
                            end

              _add_attribute(attribute_name, declaration)
            end

            _type_declaration

            AttributeCreated.new(attribute_name)
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
          _type_declaration[:required] ||= []
          _type_declaration[:required] << attribute_name.to_sym
        end

        def _add_to_defaults(attribute_name, value)
          _type_declaration[:defaults] ||= {}
          _type_declaration[:defaults][attribute_name.to_sym] = value
        end

        def _type_declaration
          @_type_declaration ||= begin
            sugar = {
              type: "::attributes",
              element_type_declarations: {}
            }

            handler = Domain.current.foobara_type_builder.handler_for_class(Handlers::ExtendAttributesTypeDeclaration)
            handler.desugarize(sugar)
          end
        end
      end
    end
  end
end
