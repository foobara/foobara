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
                    :request_mutators,
                    :response_mutators,
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
        response_mutators: nil,
        request_mutators: nil,
        serializers: nil,
        allowed_rule: nil,
        requires_authentication: nil,
        authenticator: nil,
        aggregate_entities: nil,
        atomic_entities: nil
      )
        if allowed_rule && authenticator && requires_authentication.nil?
          requires_authentication = true
        end

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
        self.response_mutators = response_mutators
        self.request_mutators = request_mutators
        self.serializers = serializers
        self.allowed_rule = allowed_rule
        self.requires_authentication = requires_authentication
        self.authenticator = authenticator

        # A bit hacky... we should check if we need to shim in a LoadDelegatedAttributesEntitiesPreCommitTransformer
        unless aggregate_entities
          # It's possible delegates have been added or removed via the result transformers...
          # We should figure out a way to check the transformed result type instead.
          if _has_delegated_attributes?(command_class.result_type)
            self.pre_commit_transformers = [
              *self.pre_commit_transformers,
              CommandConnectors::Transformers::LoadDelegatedAttributesEntitiesPreCommitTransformer
            ].uniq
          end
        end
      end

      def _has_delegated_attributes?(type)
        type&.extends?(BuiltinTypes[:model]) && type.target_class&.has_delegated_attributes?
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

      def foobara_manifest
        transformed_command_class.foobara_manifest.merge(super).merge(
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
            capture_unknown_error,
            inputs_transformers,
            result_transformers,
            errors_transformers,
            pre_commit_transformers,
            response_mutators,
            request_mutators,
            serializers,
            allowed_rule,
            requires_authentication,
            authenticator,
            result_has_sensitive_types?
          ]
        ) && scoped_path == command_class.scoped_path
                                         command_class
                                       else
                                         Foobara::TransformedCommand.subclass(
                                           command_class,
                                           scoped_namespace:,
                                           full_command_name:,
                                           command_name:,
                                           capture_unknown_error:,
                                           inputs_transformers:,
                                           result_transformers:,
                                           errors_transformers:,
                                           pre_commit_transformers:,
                                           response_mutators:,
                                           request_mutators:,
                                           serializers:,
                                           allowed_rule:,
                                           requires_authentication:,
                                           authenticator:
                                         )
                                       end
      end

      # TODO: what to do if the whole return type is sensitive? return nil?
      def result_has_sensitive_types?
        result_type = command_class.result_type

        if result_type.nil?
          false
        elsif result_type.sensitive?
          # :nocov:
          # TODO: we should convert it to nil I suppose
          raise "Not sure yet how to handle a sensitive result type hmmmm..."
          # :nocov:
        else
          command_class.result_type.has_sensitive_types?
        end
      end
    end
  end
end
