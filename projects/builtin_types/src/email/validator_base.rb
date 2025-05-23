module Foobara
  module BuiltinTypes
    module Email
      class ValidatorBase < TypeDeclarations::Validator
        singleton_class.define_method :error_classes do
          @error_classes ||= begin
            error_short_name = "#{Util.non_full_name(self)}Error"
            error_class_name = "#{name}::#{error_short_name}"

            error_class = Util.make_class(error_class_name, Value::DataError) do
              class << self
                def context_type_declaration
                  {
                    value: :duck,
                    regex: :duck, # TODO: make regex type
                    negate_regex: :duck # TODO: make :boolean
                  }
                end

                def message
                  Util.humanize(symbol)
                end
              end
            end

            [error_class]
          end
        end

        def regex
          # :nocov:
          raise "subclass responsibility"
          # :nocov:
        end

        def negate_regex?
          false
        end

        def error_context(value)
          {
            value:,
            regex:,
            negate_regex: negate_regex?
          }
        end

        def validation_errors(email)
          build_error if email.send(negate_regex? ? :=~ : :!~, regex)
        end
      end

      module Validators
        # This is getting kind of convoluted. TODO: unroll all of this into different files instead of dynamically
        # creating classes here
        {
          true => {
            must_have_an_at_sign: /\A[^@]+\z/,
            cannot_have_multiple_at_signs: /@.*@/,
            first_part_cannot_start_with_or_end_with_a_dot_or_have_two_dots_in_a_row: /(^\.|\.@|\.\..*@)/,
            domain_cannot_start_with_or_end_with_a_hyphen: /(@-|-$)/,
            first_part_cannot_be_empty: /\A@/,
            second_part_cannot_be_empty: /@\z/
          },
          false => {
            cannot_exceed_64_characters: /\A.{0,64}\z/,
            first_part_has_bad_characters: /\A[.a-z\d_!#$%&'*+\/=?^‘{|}~-]+@/,
            second_part_has_bad_characters: /@[.a-z\d-]+\z/
          }
        }.each do |negate, rule_set|
          rule_set.each_pair do |symbol, regex|
            class_name = "#{name}::#{Util.classify(symbol)}"

            Util.make_class(class_name, ValidatorBase) do
              define_method :applicable? do |value|
                # TODO: hmmm, I wonder how we can short-circuit these checks if :allow_nil matches??
                value.is_a?(::String)
              end

              define_method :regex do
                regex
              end

              if negate
                define_method :negate_regex? do
                  true
                end
              end
            end
          end
        end
      end
    end
  end
end
