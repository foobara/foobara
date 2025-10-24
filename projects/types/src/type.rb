module Foobara
  module Types
    # TODO: move casting interface to here?
    class Type < Value::Processor::Pipeline
      include Concerns::SupportedProcessorRegistration
      include Concerns::Reflection
      include IsManifestable

      foobara_instances_are_namespaces!

      class << self
        def requires_declaration_data?
          true
        end
      end

      attr_accessor :base_type,
                    :structure_count,
                    :is_builtin,
                    :name,
                    :description,
                    :sensitive,
                    :sensitive_exposed,
                    :element_type_loader,
                    :element_types_loader

      attr_reader :type_symbol,
                  :casters,
                  :transformers,
                  :validators,
                  :target_classes,
                  :processor_classes_requiring_type,
                  :element_processors,
                  :cast_even_if_instance_of_target_type

      attr_writer :element_types,
                  :element_type

      def initialize(
        declaration_data,
        target_classes:,
        base_type:,
        description: nil,
        name: "anonymous",
        casters: [],
        transformers: [],
        validators: [],
        element_processors: nil,
        structure_count: nil,
        processor_classes_requiring_type: nil,
        sensitive: nil,
        sensitive_exposed: nil,
        **opts
      )
        self.declaration_data = declaration_data
        self.sensitive = sensitive
        self.sensitive_exposed = sensitive_exposed
        self.base_type = base_type
        self.description = description
        self.name = name
        self.casters = [*casters, *base_type&.casters]
        self.transformers = [*transformers, *base_type&.transformers]
        self.validators = [*validators, *base_type&.validators]
        self.element_processors = [*element_processors, *base_type&.element_processors]

        self.structure_count = structure_count
        self.target_classes = Util.array(target_classes)
        self.processor_classes_requiring_type = processor_classes_requiring_type

        super(declaration_data, **opts.merge(processors:, prioritize: false))

        apply_all_processors_needing_type!

        validate_processors!
      end

      # TODO: replace the concept of builtin? with primitive?
      def primitive?
        declaration_data.is_a?(::Symbol)
      end

      def derived?
        declaration_data.is_a?(::Hash)
      end

      def sensitive?
        sensitive
      end

      def sensitive_exposed?
        sensitive_exposed
      end

      def element_type
        lru_cache.cached([self, :element_type]) do
          if element_type_loader
            element_type_loader.resolve(self)
          else
            base_type&.element_type
          end
        end
      end

      def element_types
        lru_cache.cached([self, :element_types]) do
          if element_types_loader
            element_types_loader.resolve(self)
          else
            base_type&.element_types
          end
        end
      end

      def has_sensitive_types?
        return true if sensitive?

        # TODO: this is a hack... come up with a better/separate way to detect types with private attributes
        if declaration_data.is_a?(::Hash)
          private = declaration_data[:private]
          return true if private.is_a?(::Array) && !private.empty?
        end

        if element_type
          return true if element_type.has_sensitive_types?
        end

        if element_types
          types = if element_types.is_a?(::Hash)
                    element_types.values
                  else
                    [*element_types]
                  end

          types.any?(&:has_sensitive_types?)
        end
      end

      def apply_all_processors_needing_type!
        each_processor_class_requiring_type do |processor_class|
          # TODO: is this a smell?
          processor = processor_class.new(self)

          category = case processor
                     when Value::Caster
                       casters
                     when Value::Validator
                       # :nocov:
                       validators
                       # :nocov:
                     when Value::Transformer
                       # :nocov:
                       transformers
                       # :nocov:
                     when Types::ElementProcessor
                       # :nocov:
                       element_processors
                       # :nocov:
                     else
                       # TODO: add validator that these are all fine so we don't have to bother here...
                       # :nocov:
                       raise "Not sure where to put #{processor}"
                       # :nocov:
                     end

          symbol = processor.symbol
          category.delete_if { |p| p.symbol == symbol }

          category << processor
          clear_caches
        end
      end

      def clear_caches
        [
          :@value_validator,
          :@processors,
          :@value_caster,
          :@value_transformer,
          :@element_processor,
          :@possible_errors,
          :@processors_without_casters
        ].each do |instance_variable|
          if instance_variable_defined?(instance_variable)
            remove_instance_variable(instance_variable)
          end
        end
      end

      def remove_caster_instances_of(klass)
        self.casters = casters.reject do |caster|
          caster.is_a?(klass)
        end

        clear_caches
      end

      def remove_processor_by_symbol(symbol)
        [
          casters,
          element_processors,
          processor_classes_requiring_type,
          processors,
          transformers,
          validators
        ].each do |processor_collection|
          processor_collection&.delete_if { |p| p.symbol == symbol }
        end
        supported_processor_classes&.each { |processor_hash| processor_hash.delete(symbol) }
        processor_classes_requiring_type&.delete_if { |p| p.symbol == symbol }
        clear_caches
      end

      def each_processor_class_requiring_type(&block)
        base_type&.each_processor_class_requiring_type(&block)

        processor_classes_requiring_type&.each do |processor_class|
          block.call(processor_class)
        end
      end

      def validate_processors!
        all = [casters, transformers, validators, element_processors]

        all.each do |processor_group|
          processor_group.each.with_index do |processor, index|
            if processor.requires_parent_declaration_data?
              processor_group[index] = processor.dup_processor(parent_declaration_data: declaration_data)
            end
          end

          processor_group.group_by(&:symbol).each_pair do |symbol, members|
            if members.size > 1
              if members.map { |m| m.class.name }.uniq.size == members.size
                members[1..].each do |member|
                  processor_group.delete(member)
                end
              else
                # :nocov:
                raise "Type #{name} has multiple processors with symbol #{symbol}"
                # :nocov:
              end
            end
          end
        end

        clear_caches
      end

      def target_class
        if target_classes.empty?
          # :nocov:
          # TODO: We really need a better error message when we hit this point in the code path.
          # One thing that can cause this is if you create a custom type called :model but it isn't loaded
          # yet and we accidentally are referring to the builtin :model type.  This error message doesn't reveal
          # that you need to require the custom :model.
          raise "No target classes"
          # :nocov:
        elsif target_classes.size > 1
          # :nocov:
          raise "Cannot use #target_class because this type has multiple target_classes"
          # :nocov:
        end

        target_classes.first
      end

      def extends?(type)
        case type
        when Type
          extends_type?(type)
        when Symbol, String
          concrete_type = created_in_namespace.foobara_lookup_type(type)
          if concrete_type.nil?
            # :nocov:
            raise "No type found for #{type}"
            # :nocov:
          end

          extends_type?(concrete_type)
        else
          # :nocov:
          raise ArgumentError, "Expected a Type or a Symbol/String, but got #{type.inspect}"
          # :nocov:
        end
      end

      def extends_directly?(type)
        case type
        when Type
          base_type == type
        when Symbol, String
          concrete_type = created_in_namespace.foobara_lookup_type(type)

          if concrete_type.nil?
            # :nocov:
            raise "No type found for #{type}"
            # :nocov:
          end

          extends_directly?(concrete_type)
        else
          # :nocov:
          raise ArgumentError, "Expected a Type or a Symbol/String, but got #{type.inspect}"
          # :nocov:
        end
      end

      def extends_type?(type)
        return true if self == type

        unless type
          # :nocov:
          raise ArgumentError, "Expected a type but got nil"
          # :nocov:
        end

        if registered?
          if type.registered?
            if type.foobara_manifest_reference == foobara_manifest_reference
              return true
            end
          end
        end

        base_type&.extends_type?(type)
      end

      def processors=(...)
        clear_caches
        super
      end

      def type_symbol=(type_symbol)
        @scoped_path ||= type_symbol.to_s.split("::")
        clear_caches
        @type_symbol = type_symbol.to_sym
      end

      def cast_even_if_instance_of_target_type=(flag)
        clear_caches
        @cast_even_if_instance_of_target_type = flag
      end

      def casters=(processors)
        clear_caches
        @casters = processors
      end

      def add_caster(processor)
        casters << processor
        clear_caches
      end

      def transformers=(processors)
        clear_caches
        @transformers = processors
      end

      def validators=(processors)
        clear_caches
        @validators = processors
      end

      def target_classes=(processors)
        clear_caches
        @target_classes = processors
      end

      def processor_classes_requiring_type=(processors)
        clear_caches
        @processor_classes_requiring_type = processors
      end

      def element_processors=(processors)
        clear_caches
        @element_processors = processors
      end

      def full_type_symbol
        return @full_type_symbol if defined?(@full_type_symbol)

        @full_type_symbol ||= if scoped_path_set?
                                scoped_full_name.to_sym
                              end
      end

      def processors
        @processors ||= [
          value_caster,
          value_transformer,
          value_validator,
          element_processor
        ].compact.sort_by(&:priority)
      end

      def value_caster
        return @value_caster if defined?(@value_caster)

        # We make this exception for :duck because it will match any instance of
        # Object but AllowNil will match nil which is also an instance of Object.
        # This results in two matching casters. Instead of figuring out a way to make one
        # conditional on the other we will just turn off this unique enforcement for :duck
        enforce_unique = if declaration_data.is_a?(::Hash)
                           declaration_data[:type] != :duck
                         else
                           true
                         end

        Namespace.use created_in_namespace do
          @value_caster = Value::Processor::Casting.new(
            { cast_to: reference_or_declaration_data },
            casters:,
            target_classes:,
            enforce_unique:,
            cast_even_if_instance_of_target_type:
          )
        end
      end

      def applicable?(value)
        !value_caster.needs_cast?(value) || value_caster.can_cast?(value)
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
        return @value_transformer if defined?(@value_transformer)

        @value_transformer = if transformers && !transformers.empty?
                               Value::Processor::Pipeline.new(processors: transformers)
                             end
      end

      # TODO: figure out how to safely memoize stuff so like this for performance reasons
      # A good way, but potentially a decent amount of work, is to have a class that takes value to its initialize
      # method.
      def value_validator
        return @value_validator if defined?(@value_validator)

        @value_validator = if validators && !validators.empty?
                             Value::Processor::Pipeline.new(processors: validators)
                           end
      end

      def element_processor
        return @element_processor if defined?(@element_processor)

        @element_processor = if element_processors && !element_processors.empty?
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
        remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

        if registered?
          # TODO: we should just use the symbol and nothing else in this context instead of a hash with 1 element.
          if scoped_unregistered?
            unregistered_foobara_manifest_reference.to_sym
          else
            foobara_manifest_reference.to_sym
          end
        elsif remove_sensitive
          TypeDeclarations.remove_sensitive_types(declaration_data)
        else
          declaration_data
        end
      end

      # TODO: put this somewhere else
      def foobara_manifest_reference
        scoped_full_name
      end

      def foobara_manifest
        to_include = TypeDeclarations.foobara_manifest_context_to_include
        remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?
        include_processors = TypeDeclarations.include_processors?

        types = []

        types_depended_on.each do |dependent_type|
          if dependent_type.registered?
            types << dependent_type.foobara_manifest_reference
            if to_include
              to_include << dependent_type
            end
          end
        end

        possible_errors_manifests = possible_errors.map do |possible_error|
          [possible_error.key.to_s, possible_error.foobara_manifest]
        end.sort.to_h

        declaration_data = self.declaration_data

        if remove_sensitive
          declaration_data = TypeDeclarations.remove_sensitive_types(declaration_data)
        end

        h = Util.remove_blank(
          name:,
          target_classes: target_classes.map(&:name).sort,
          declaration_data:,
          types_depended_on: types.sort,
          possible_errors: possible_errors_manifests,
          builtin: builtin?
        ).merge(description:, base_type: base_type_for_manifest&.full_type_name&.to_sym)

        if sensitive?
          h[:sensitive] = true
        end

        if sensitive_exposed?
          h[:sensitive_exposed] = true
        end

        if include_processors
          h.merge!(
            supported_processor_manifest.merge(
              Util.remove_blank(processors: processor_manifest)
            )
          )
        end

        target_classes.sort_by(&:name).each do |target_class|
          if target_class.respond_to?(:foobara_manifest)
            h.merge!(target_class.foobara_manifest)
          end
        end

        super.merge(h)
      end

      # TODO: replace the concept of builtin? with primitive? and delete this method since
      # primitive? already exists.
      def builtin?
        is_builtin
      end

      def base_type_for_manifest
        base_type
      end

      def supported_processor_manifest
        to_include = TypeDeclarations.foobara_manifest_context_to_include

        supported_casters = []
        supported_transformers = []
        supported_validators = []
        supported_processors = []

        all_supported_processor_classes.each do |processor_class|
          if to_include
            to_include << processor_class
          end

          target = if processor_class < Value::Caster
                     supported_casters
                   elsif processor_class < Value::Validator
                     supported_validators
                   elsif processor_class < Value::Transformer
                     supported_transformers
                   else
                     supported_processors
                   end

          target << processor_class.foobara_manifest_reference
        end

        Util.remove_blank(
          supported_casters: supported_casters.sort,
          supported_transformers: supported_transformers.sort,
          supported_validators: supported_validators.sort,
          supported_processors: supported_processors.sort
        )
      end

      def processor_manifest
        to_include = TypeDeclarations.foobara_manifest_context_to_include

        casters_manifest = []
        transformers_manifest = []
        validators_manifest = []
        caster_classes_manifest = []
        transformer_classes_manifest = []
        validator_classes_manifest = []

        casters.each do |caster|
          klass = caster.class
          if to_include
            to_include << klass
          end
          caster_classes_manifest << klass.foobara_manifest_reference

          if caster.scoped_path_set?
            if to_include
              to_include << caster
            end
            casters_manifest << caster.foobara_manifest_reference
          end
        end

        transformers.each do |transformer|
          klass = transformer.class
          if to_include
            to_include << klass
          end
          transformer_classes_manifest << klass.foobara_manifest_reference

          if transformer.scoped_path_set?
            if to_include
              to_include << transformer
            end
            transformers_manifest << transformer.foobara_manifest_reference
          end
        end

        validators.each do |validator|
          klass = validator.class
          if to_include
            to_include << klass
          end
          validator_classes_manifest << klass.foobara_manifest_reference

          if validator.scoped_path_set?
            if to_include
              to_include << validator
            end
            validators_manifest << validator.foobara_manifest_reference
          end
        end

        Util.remove_blank(
          casters: casters_manifest.sort,
          caster_classes: caster_classes_manifest.sort,
          transformers: transformers_manifest.sort,
          transformer_classes: transformer_classes_manifest.sort,
          validators: validators_manifest.sort,
          validator_classes: validator_classes_manifest.sort
        )
      end

      def registered?
        !!type_symbol
      end
    end
  end

  Type = Foobara::Types::Type
end
