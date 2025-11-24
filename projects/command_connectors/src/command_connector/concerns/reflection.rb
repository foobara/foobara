module Foobara
  class CommandConnector
    module Concerns
      module Reflection
        include Concern

        def foobara_manifest
          Namespace.use command_registry do
            foobara_manifest_in_current_namespace
          end
        end

        # TODO: figure out how this is used
        def all_exposed_type_names
          # TODO: cache this or better yet cache #foobara_manifest
          foobara_manifest[:type].keys.sort.map(&:to_s)
        end

        private

        # TODO: try to break this giant method up
        def foobara_manifest_in_current_namespace
          process_delayed_connections

          to_include = Set.new

          to_include << command_registry.global_organization
          to_include << command_registry.global_domain

          command_registry.foobara_each_command(
            mode: Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE
          ) do |exposed_command|
            to_include << exposed_command
          end

          included = Set.new

          additional_to_include = Set.new

          h = {
            organization: {},
            domain: {},
            type: {},
            command: {},
            error: {}
          }

          if TypeDeclarations.include_processors?
            h.merge!(
              processor: {},
              processor_class: {}
            )
          end

          TypeDeclarations.with_manifest_context(to_include: additional_to_include, remove_sensitive: true) do
            until to_include.empty? && additional_to_include.empty?
              object = nil

              if to_include.empty?
                until additional_to_include.empty?
                  o = additional_to_include.first
                  additional_to_include.delete(o)

                  if o.is_a?(::Module)
                    if o.foobara_domain? || o.foobara_organization?
                      unless o.foobara_root_namespace == command_registry
                        next
                      end
                    elsif o.is_a?(::Class) && o < Foobara::Command
                      next
                    end
                  elsif o.is_a?(Types::Type)
                    if o.sensitive?
                      # :nocov:
                      raise UnexpectedSensitiveTypeInManifestError,
                            "Unexpected sensitive type in manifest: #{o.scoped_full_path}. " \
                            "Make sure these are not included."
                      # :nocov:
                    else

                      mode = Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE
                      domain_name = o.foobara_domain.scoped_full_name

                      exposed_domain = command_registry.foobara_lookup_domain(domain_name, mode:)

                      exposed_domain ||= command_registry.build_and_register_exposed_domain(domain_name)

                      # Since we don't know which other domains/orgs creating this domain might have created,
                      # we will just add them all to be included just in case
                      command_registry.foobara_all_domain(mode:).each do |exposed_domain|
                        additional_to_include << exposed_domain
                      end

                      command_registry.foobara_all_organization(mode:).each do |exposed_organization|
                        additional_to_include << exposed_organization
                      end
                    end
                  end

                  object = o
                  break
                end
              else
                object = to_include.first
                to_include.delete(object)
              end

              break unless object
              next if included.include?(object)

              manifest_reference = object.foobara_manifest_reference.to_sym

              category_symbol = command_registry.foobara_category_symbol_for(object)

              unless category_symbol
                # :nocov:
                raise "no category symbol for #{object}"
                # :nocov:
              end

              namespace = if object.is_a?(Types::Type)
                            object.created_in_namespace
                          else
                            Foobara::Namespace.current
                          end

              # TODO: do we really need to enter the namespace here for this?
              h[category_symbol][manifest_reference] = Foobara::Namespace.use namespace do
                object.foobara_manifest
              end

              included << object
            end
          end

          h[:domain].each_value do |domain_manifest|
            # TODO: hack, we need to trim types down to what is actually included in this manifest
            domain_manifest[:types] = domain_manifest[:types].select do |type_name|
              h[:type].key?(type_name.to_sym)
            end
          end

          h = normalize_manifest(h)
          patch_up_broken_parents_for_errors_with_missing_command_parents(h)
        end

        def normalize_manifest(manifest_hash)
          manifest_hash.map do |key, entries|
            [key, entries.sort.to_h]
          end.sort.to_h
        end

        def patch_up_broken_parents_for_errors_with_missing_command_parents(manifest_hash)
          root_manifest = Manifest::RootManifest.new(manifest_hash)

          error_category = {}

          root_manifest.errors.each do |error|
            error_manifest = if (error.parent_category == :command || error.parent_category == :organization) &&
                                !root_manifest.contains?(error.parent_name, error.parent_category)
                               domain = error.domain
                               index = domain.scoped_full_path.size

                               fixed_scoped_path = error.scoped_full_path[index..]
                               fixed_scoped_name = fixed_scoped_path.join("::")
                               fixed_scoped_prefix = fixed_scoped_path[..-2]
                               fixed_parent = [:domain, domain.reference]

                               error.relevant_manifest.merge(
                                 parent: fixed_parent,
                                 scoped_path: fixed_scoped_path,
                                 scoped_name: fixed_scoped_name,
                                 scoped_prefix: fixed_scoped_prefix
                               )
                             else
                               error.relevant_manifest
                             end

            error_category[error.scoped_full_name.to_sym] = error_manifest
          end

          manifest_hash.merge(error: error_category)
        end
      end
    end
  end
end
