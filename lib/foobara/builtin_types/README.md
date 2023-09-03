# Adding a new builtin type

Let's go through the steps of adding a String builtin type

## Create a directory for the new type

```bash
mkdir lib/foobara/builtin_types/string 
```

## Add Casters

```bash
mkdir lib/foobara/builtin_types/string/casters
```

We always need a caster that matches things that don't need to be cast.

(TODO: maybe change this so it's not necessary anymore?)

in `lib/foobara/builtin_types/string/casters/string.rb`

```ruby 
module Foobara
  module BuiltinTypes
    module String
      module Casters
        class String < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::String)
          end
        end
      end
    end
  end
end
```

Let's also support casting Symbol to String...

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
$ bin/console
irb(main):001:0> type = Foobara::TypeDeclarations::Namespace.type_for_declaration(:string, :downcase, max_length: 10)
=> #<Foobara::Types::Type:0x00007fb12f5ca160 ...>
irb(main):002:0> type.process_value!("Foo Bar")
=> "foo bar"
irb(main):003:0> type.process_value("Foo Bar Baz").errors.first.message
=> "Max length exceeded. Cannot be longer than 10"
```
