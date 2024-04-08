Foobara.require_project_file("value", "processor/multi")

module Foobara
  module Value
    class Processor
      class Pipeline < Multi
        class << self
          def foobara_manifest(to_include:)
            # :nocov:
            super.merge(processor_type: :pipeline)
            # :nocov:
          end
        end

        def process_outcome(old_outcome)
          processors.inject(old_outcome) do |outcome, processor|
            old_result = outcome.result

            if old_result.is_a?(::Hash)
              if old_result.dig("element_type_declarations", "email")
                #                binding.pry
              end
            end

            processor.process_outcome(outcome).tap do |o|
              r = o.result
              if r.is_a?(::Hash)
                begin
                  s = JSON.generate(r)
                  # binding.pry if s =~ /email/ && s.size < 1000
                  if r.dig("element_type_declarations", "email")
                    #   binding.pry
                  end
                rescue => e
                end
              end
            end
          end
        end

        def process_value(value)
          process_outcome(Outcome.success(value))
        end
      end
    end
  end
end
