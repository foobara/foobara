module Foobara
  module Types
    # TODO: move casting interface to here?
    class Type < Value::Processor::Pipeline
      include Concerns::SupportedProcessorRegistration

      class << self
        attr_accessor :root_type

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
                    :type_registry,
                    :target_classes

      def initialize(
        *args,
        target_classes:,
        type_registry: Types.global_registry,
        base_type: self.class.root_type,
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
        self.type_registry = type_registry

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
        type_registry_name = type_registry&.name

        if type_registry_name && !type_registry_name.empty?
          "#{type_registry_name}::#{name}"
        else
          name
        end
      end

      def manifest
        h = Util.remove_empty(
          target_classes: target_classes.map(&:name),
          base_type: base_type&.full_type_name,
          declaration_data:,
          supported_processors: supported_processor_manifest,
          processors: processor_manifest
        )

        target_classes.each do |target_class|
          if target_class.respond_to?(:foobara_manifest)
            h.merge!(target_class.foobara_manifest)
          end
        end

        h
      end

      def manifest_hash
        {
          name.to_sym => manifest
        }
      end

      def supported_processor_manifest
        supported_transformers = {}
        supported_validators = {}
        supported_processors = {}

        all_supported_processor_classes.each do |processor_class|
          processor_manifest = processor_class.manifest

          target = if processor_class < Value::Transformer
                     supported_transformers
                   elsif processor_class < Value::Validator
                     supported_validators
                   else
                     supported_processors
                   end

          symbol = processor_class.symbol

          if target.key?(symbol)
            # :nocov:
            raise "Already registered #{symbol}"
            # :nocov:
          end

          target[symbol] = processor_manifest
        end

        Util.remove_empty(
          supported_transformers:,
          supported_validators:,
          supported_processors:
        )
      end

      def processor_manifest
        casters_manifest = {}
        transformers_manifest = {}
        validators_manifest = {}

        casters.each do |caster|
          symbol = caster.symbol

          if casters_manifest.key?(symbol)
            # :nocov:
            raise "Already registered casters_manifest with #{symbol.inspect}"
            # :nocov:
          end

          casters_manifest[symbol] = caster.manifest
        end

        transformers.each do |transformer|
          symbol = transformer.symbol

          if transformers_manifest.key?(symbol)
            # :nocov:
            raise "Already registered transformers_manifest with #{symbol.inspect}"
            # :nocov:
          end

          transformers_manifest[symbol] = transformer.manifest
        end

        validators.each do |validator|
          symbol = validator.symbol

          if validators_manifest.key?(symbol)
            # :nocov:
            raise "Already registered validators_manifest with #{symbol.inspect}"
            # :nocov:
          end

          validators_manifest[symbol] = validator.manifest
        end

        Util.remove_empty(
          casters: casters_manifest,
          transformers: transformers_manifest,
          validators: validators_manifest
        )
      end
    end
  end
end
