module Foobara
  module Callback
    module Concerns
      module Type
        extend ActiveSupport::Concern

        class_methods do
          def type
            @type ||= name.demodulize.gsub(/Block$/, "").underscore.to_sym
          end
        end
      end
    end
  end
end
