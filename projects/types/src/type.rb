module Foobara
  module Types
    # TODO: move casting interface to here?
    class Type < Value::Processor::Pipeline
      include Concerns::SupportedProcessorRegistration
      include Concerns::Reflection

      class << self
        def requires_declaration_data?
          true
        end
      end

      # TODO: needed/useful transformers/validators to implement:
      #
      # allow_empty (validation at attribute level)
      # allow_nil (validation at attribute level)
      # one_of (validation at attribute level)

      attr_accessor :base_type,
                    :casters,
                    :transformers,
                    :validators,
                    :element_processors,
                    :structure_count,
                    :element_types,
                    :element_type,
                    :raw_declaration_data,
                    :name,
                    :target_classes
      attr_reader :type_symbol

      def initialize(
        *args,
        target_classes:,
        base_type:,
        name: "anonymous",
        casters: [],
        transformers: [],
        validators: [],
        element_processors: nil,
        element_type: nil,
        element_types: nil,
        structure_count: nil,
        **opts
      )
        self.base_type = base_type
        self.casters = Util.array(casters)
        self.transformers = transformers
        self.validators = validators
        self.element_processors = element_processors
        self.structure_count = structure_count
        # TODO: combine these maybe with the term "children_types"?
        self.element_types = element_types
        self.element_type = element_type
        self.name = name
        self.target_classes = Util.array(target_classes)

        super(*args, **opts.merge(processors:, prioritize: false))
      end

      def target_class
        if target_classes.empty?
          # :nocov:
          raise "No target classes"
          # :nocov:
        elsif target_classes.size > 1
          # :nocov:
          raise "Cannot use #target_class because this type has multiple target_classes"
          # :nocov:
        end

        target_classes.first
      end

      def extends_type?(type)
        base_type == type || base_type&.extends_type?(type)
      end

      def extends_symbol?(symbol)
        type_symbol == symbol || base_type&.extends_symbol?(symbol)
      end

      def type_symbol=(type_symbol)
        @scoped_path ||= [type_symbol.to_s]
        @type_symbol = type_symbol
      end

      def processors
        [
          value_caster,
          value_transformer,
          value_validator,
          element_processor
        ].compact
      end

      def value_caster
        # TODO: how can declaration_data be blank? That seems really strange...
        Value::Processor::Casting.new({ cast_to: declaration_data }, casters:, target_classes:)
      end

      def applicable?(value)
        value_caster.can_cast?(value)
      end

      foobara_delegate :needs_cast?, to: :value_caster

      def cast(value)
        value_caster.process_value(value)
      end

      def cast!(value)
        value_caster.process_value!(value)
      end

      # TODO: an interesting thought... we have Processor and then a subclass of Processor and then an instance of
      # processor that encapsulates the declaration_data for that processor. But then we pass `value` to every
      # method in the instance of the processor as needed. This means it can't really memoize stuff. Should we create
      # an instance of something from the instance of the processor and then ask it questions?? TODO: try this
      def value_transformer
        if transformers && !transformers.empty?
          Value::Processor::Pipeline.new(processors: transformers)
        end
      end

      # TODO: figure out how to safely memoize stuff so like this for performance reasons
      # A good way, but potentially a decent amount of work, is to have a class that takes value to its initialize
      # method.
      def value_validator
        if validators && !validators.empty?
          Value::Processor::Pipeline.new(processors: validators)
        end
      end

      def element_processor
        if element_processors && !element_processors.empty?
          Value::Processor::Pipeline.new(processors: element_processors)
        end
      end

      # TODO: some way of memoizing these values? Would need to introduce a new class that takes the value to its
      # constructor
      def validation_errors(value)
        value = cast!(value)
        if value_transformer
          value = value_transformer.process_value!(value)
        end

        if value_validator
          value_validator.process_value(value).errors
        else
          []
        end
      end

      def full_type_name
        scoped_full_name
      end

      def reference_or_declaration_data(declaration_data = self.declaration_data)
        if registered?
          # TODO: we should just use the symbol and nothing else in this context instead of a hash with 1 element.
          { type: foobara_manifest_reference.to_sym }
        else
          declaration_data
        end
      end

      # TODO: put this somewhere else
      def foobara_manifest_reference
        scoped_full_name
      end

      def foobara_manifest(to_include:)
        types = []

        possible_errors_manifests = possible_errors.map do |possible_error|
          [possible_error.key.to_s, possible_error.foobara_manifest(to_include:)]
        end

        h = {
          name:,
          target_classes: target_classes.map(&:name),
          base_type: base_type&.full_type_name&.to_sym,
          declaration_data:,
          types_depended_on: types,
          possible_errors: possible_errors_manifests
        }

        types_depended_on.each do |dependent_type|
          if dependent_type.registered?
            types << dependent_type.foobara_manifest_reference
            to_include << dependent_type
          end
        end

        h.merge!(
          supported_processor_manifest(to_include).merge(
            processors: processor_manifest(to_include)
          )
        )

        target_classes.each do |target_class|
          if target_class.respond_to?(:foobara_manifest)
            h.merge!(target_class.foobara_manifest(to_include:))
          end
        end

        super.merge(h)
      end

      def supported_processor_manifest(to_include)
        supported_transformers = []
        supported_validators = []
        supported_processors = []

        all_supported_processor_classes.each do |processor_class|
          to_include << processor_class

          target = if processor_class < Value::Transformer
                     supported_transformers
                   elsif processor_class < Value::Validator
                     supported_validators
                   else
                     supported_processors
                   end

          target << processor_class.foobara_manifest_reference
        end

        {
          supported_transformers:,
          supported_validators:,
          supported_processors:
        }
      end

      def processor_manifest(to_include)
        casters_manifest = []
        transformers_manifest = []
        validators_manifest = []
        caster_classes_manifest = []
        transformer_classes_manifest = []
        validator_classes_manifest = []

        casters.each do |caster|
          klass = caster.class
          to_include << klass
          caster_classes_manifest << klass.foobara_manifest_reference

          if caster.scoped_path_set?
            to_include << caster
            casters_manifest << caster.foobara_manifest_reference
          end
        end

        transformers.each do |transformer|
          klass = transformer.class
          to_include << klass
          transformer_classes_manifest << klass.foobara_manifest_reference

          if transformer.scoped_path_set?
            to_include << transformer
            transformers_manifest << transformer.foobara_manifest_reference
          end
        end

        validators.each do |validator|
          klass = validator.class
          to_include << klass
          validator_classes_manifest << klass.foobara_manifest_reference

          if validator.scoped_path_set?
            to_include << validator
            validators_manifest << validator.foobara_manifest_reference
          end
        end

        {
          casters: casters_manifest,
          caster_classes: caster_classes_manifest,
          transformers: transformers_manifest,
          transformer_classes: transformer_classes_manifest,
          validators: validators_manifest,
          validator_classes: validator_classes_manifest
        }
      end

      def registered?
        !!type_symbol
      end
    end
  end
end
