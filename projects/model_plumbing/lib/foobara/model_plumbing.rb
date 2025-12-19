module Foobara
  module ModelPlumbing
    class << self
      def install!
        Model.on_reregister do
          GlobalDomain.foobara_each_command(&:handle_reregistered_types!)
        end
      end
    end
  end
end

Foobara.project("model_plumbing", project_path: "#{__dir__}/../..")
