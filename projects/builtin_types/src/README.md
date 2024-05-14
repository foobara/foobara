# Adding a new builtin type

Note that adding a custom type is a different process involving writing handlers/desugarizers/declaration validators.
TODO: add information to either this document or another about adding desugarizers, type declaration handlers,
and type declaration validators.

Let's go through the steps of adding a String builtin type

## Create a directory for the new type

```bash
mkdir lib/foobara/builtin_types/string 
```

## Add Casters if needed

```bash
mkdir lib/foobara/builtin_types/string/casters
```

in `lib/foobara/builtin_types/string/casters/symbol.rb`

```ruby

module Foobara
  module BuiltinTypes
    module String
      module Casters
        class Symbol < Value::Caster
          def applicable?(value)
            value.is_a?(::Symbol)
          end

          def applies_message
            "be a Symbol"
          end

          def cast(string)
            string.to_s
          end
        end
      end
    end
  end
end
```

## Creating SupportedProcessors/SupportedTransformers/SupportedValidators

Let's make a validator for length

```bash 
mkdir lib/foobara/builtin_types/string/supported_validators
```

in `lib/foobara/builtin_types/string/supported_validators/max_length.rb`

```ruby

module Foobara
  module BuiltinTypes
    module String
      module SupportedValidators
        class MaxLength < TypeDeclarations::Validator
          class MaxLengthExceededError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  value: :string,
                  max_length: :integer
                }
              end
            end
          end

          def validation_errors(string)
            if string.length > max_length
              build_error(string)
            end
          end

          def error_message(_value)
            "Max length exceeded. Cannot be longer than #{max_length} characters"
          end

          def error_context(value)
            {
              value:,
              max_length:
            }
          end
        end
      end
    end
  end
end
```

## Let's create a supported transformer

in `lib/foobara/builtin_types/string/supported_transformers/downcase.rb`

```ruby

module Foobara
  module BuiltinTypes
    module String
      module SupportedTransformers
        class Downcase < Value::Transformer
          def transform(string)
            string.downcase
          end
        end
      end
    end
  end
end
```

## Assemble our new type on boot by adding it to builtin_types.rb

in `build_and_register_all_builtins_and_install_type_declaration_extensions!` in `lib/foobara/builtin_types.rb`

```ruby
string = build_and_register!(:string, atomic_duck)
```

## Trying it out...

You could test this in a console with:

```ruby
$ bin / console
irb(main) : 001 : 0 > type = Foobara::TypeDeclarations::TypeBuilder.type_for_declaration(:string, :downcase, max_length: 10)
=> #<Foobara::Types::Type:0x00007fb12f5ca160 ...>
  irb(main) : 002 : 0 > type.process_value!("Foo Bar")
=> "foo bar"
irb(main) : 003 : 0 > type.process_value("Foo Bar Baz").errors.first.message
=> "Max length exceeded. Cannot be longer than 10"
```
