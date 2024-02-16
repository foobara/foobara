module Foobara
  class CommandRegistry
    class ExposedCommand
      include Scoped
      include IsManifestable

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

      def foobara_manifest(to_include:)
        to_include << domain
        to_include << organization

        types = transformed_command_class.types_depended_on.select(&:registered?).map do |t|
          to_include << t
          t.foobara_manifest_reference
        end.sort

        inputs_transformers = self.inputs_transformers.map { |t| t.foobara_manifest(to_include:) }
        result_transformers = self.result_transformers.map { |t| t.foobara_manifest(to_include:) }
        errors_transformers = self.errors_transformers.map { |t| t.foobara_manifest(to_include:) }
        pre_commit_transformers = self.pre_commit_transformers.map { |t| t.foobara_manifest(to_include:) }
        serializers = self.serializers.map do |s|
          if s.respond_to?(:foobara_manifest)
            to_include << s
            s.foobara_manifest_reference
          else
            { proc: s.to_s }
          end
        end

        command_class.foobara_manifest(to_include:).merge(super).merge(
          Util.remove_blank(
            scoped_category: :command,
            full_command_name:,
            types_depended_on: types,
            inputs_type: transformed_command_class.inputs_type&.reference_or_declaration_data,
            result_type: transformed_command_class.result_type&.reference_or_declaration_data,
            possible_errors: transformed_command_class.possible_errors_manifest(to_include:),
            capture_unknown_error:,
            inputs_transformers:,
            result_transformers:,
            errors_transformers:,
            pre_commit_transformers:,
            serializers:,
            requires_authentication:,
            authenticator: authenticator&.manifest
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
