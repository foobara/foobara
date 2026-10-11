module Foobara
  module ModelPlumbing
    class << self
      def install!
        Model.on_reregister do
          seen = Set.new

          Namespace.global.foobara_each do |scoped|
            if scoped.respond_to?(:handle_reregistered_types!)
              scoped.handle_reregistered_types!(seen)
            end
          end
        end

        CommandPatternImplementation.include CommandPatternImplementation::Concerns::ModelInputsType
        DomainMapper.singleton_class.prepend(ModelPlumbing::DomainMapperExtension)
      end
    end
  end
end

Foobara.project("model_plumbing", project_path: "#{__dir__}/../..")
