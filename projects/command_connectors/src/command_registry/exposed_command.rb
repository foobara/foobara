module Foobara
  class CommandRegistry
    class ExposedCommand
      include Scoped
      include IsManifestable
      include TruncatedInspect

      attr_accessor :command_class,
                    :capture_unknown_error,
                    :inputs_transformers,
                    :result_transformers,
                    :errors_transformers,
                    :pre_commit_transformers,
                    :serializers,
                    :allowed_rule,
                    :requires_authentication,
                    :authenticator,
                    :scoped_path,
                    :scoped_namespace

      def initialize(
        command_class,
        scoped_path: nil,
        suffix: nil,
        capture_unknown_error: nil,
        inputs_transformers: nil,
        result_transformers: nil,
        errors_transformers: nil,
        pre_commit_transformers: nil,
        serializers: nil,
        allowed_rule: nil,
        requires_authentication: nil,
        authenticator: nil,
        aggregate_entities: nil,
        atomic_entities: nil
      )
        if requires_authentication || allowed_rule
          errors_transformers = [
            *errors_transformers,
            Foobara::CommandConnectors::Transformers::AuthErrorsTransformer
          ].uniq
        end

        scoped_path ||= if suffix
                          *prefix, short = command_class.scoped_path
                          [*prefix, "#{short}#{suffix}"]
                        else
                          command_class.scoped_path
                        end

        if aggregate_entities
          pre_commit_transformers = [
            *pre_commit_transformers,
            Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer
          ].uniq
          serializers = [
            *serializers,
            Foobara::CommandConnectors::Serializers::AggregateSerializer
          ].uniq
        # TODO: either both should have special behavior for false or neither should
        elsif aggregate_entities == false
          pre_commit_transformers = pre_commit_transformers&.reject do |t|
            t == Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer
          end
          serializers = serializers&.reject do |s|
            s == Foobara::CommandConnectors::Serializers::AggregateSerializer
          end
        elsif atomic_entities
          serializers = [*serializers, Foobara::CommandConnectors::Serializers::AtomicSerializer].uniq
        end

        self.command_class = command_class
        self.scoped_path = scoped_path
        self.capture_unknown_error = capture_unknown_error
        self.inputs_transformers = inputs_transformers
        self.result_transformers = result_transformers
        self.errors_transformers = errors_transformers
        self.pre_commit_transformers = pre_commit_transformers
        self.serializers = serializers
        self.allowed_rule = allowed_rule
        self.requires_authentication = requires_authentication
        self.authenticator = authenticator
      end

      def full_command_name
        scoped_full_name
      end

      def command_name
        @command_name ||= Util.non_full_name(full_command_name)
      end

      def full_command_symbol
        @full_command_symbol ||= Util.underscore_sym(full_command_name)
      end

      def root_registry
        parent = scoped_namespace
        parent = parent.scoped_namespace while parent.scoped_namespace
        parent
      end

      def foobara_manifest(to_include: Set.new, remove_sensitive: true)
        # A bit of a hack here. We don't have an exposed type class to encapsulate including exposed domains/orgs
        # which leads to a bug when a global command is exposed that depends on a type in a non-global domain
        # but there being no other reason to include that non-global domain.
        transformed_command_class.types_depended_on(remove_sensitive:).select(&:registered?).each do |type|
          full_domain_name = type.foobara_domain.scoped_full_name

          unless root_registry.foobara_lookup_domain(full_domain_name)
            exposed_domain = root_registry.build_and_register_exposed_domain(full_domain_name)
            to_include << exposed_domain
            to_include << exposed_domain.foobara_organization
          end
        end

        transformed_command_class.foobara_manifest(to_include:, remove_sensitive:).merge(super).merge(
          Util.remove_blank(
            scoped_category: :command,
            domain: command_class.domain.foobara_manifest_reference,
            organization: command_class.organization.foobara_manifest_reference
          )
        )
      end

      def transformed_command_class
        @transformed_command_class ||= if Util.all_blank_or_false?(
          [
            inputs_transformers,
            result_transformers,
            errors_transformers,
            pre_commit_transformers,
            serializers,
            allowed_rule,
            requires_authentication,
            authenticator
          ]
        ) && scoped_path == command_class.scoped_path
                                         command_class
                                       else
                                         Foobara::TransformedCommand.subclass(
                                           command_class,
                                           full_command_name:,
                                           command_name:,
                                           capture_unknown_error:,
                                           inputs_transformers:,
                                           result_transformers:,
                                           errors_transformers:,
                                           pre_commit_transformers:,
                                           serializers:,
                                           allowed_rule:,
                                           requires_authentication:,
                                           authenticator:
                                         )
                                       end
      end
    end
  end
end
