# frozen_string_literal: true

module Glossarist
  module Mentions
    # Resolves parsed mention segments against a resolution context.
    # The context provides lookup callables; the resolver dispatches
    # by mention kind + target type.
    module Resolver
      module_function

      # @param mention [Hash] a parsed mention from Parser.parse
      # @param context [Hash] resolution context with lookup callables
      # @return [Hash] resolved mention with :status
      def resolve(mention, context)
        return mention if mention[:kind] == "text"

        case mention[:kind]
        when "concept", "cite"
          resolve_concept(mention, context)
        when "fig", "table", "formula"
          resolve_entity(mention, context)
        when "bib"
          resolve_bib(mention, context)
        when "link"
          { status: "external", kind: "link",
            url: mention[:target][:url], label: mention[:label] }
        when "image"
          resolve_image(mention)
        else
          { status: "unresolved", kind: mention[:kind],
            target: mention[:target], label: mention[:label] }
        end
      end

      def resolve_all(mentions, context)
        mentions.map { |m| resolve(m, context) }
      end

      def resolve_concept(mention, context)
        target = mention[:target]
        concept = lookup_concept(target, context)

        return unresolved(mention) unless concept

        result = {
          status: "resolved",
          kind: mention[:kind],
          concept: concept,
          label: mention[:label],
        }

        if mention[:kind] == "cite" && context[:concept]
          result[:source] = find_matching_source(target, context[:concept])
        end

        result
      end
      private_class_method :resolve_concept

      def resolve_entity(mention, context)
        target = mention[:target]
        entity = nil

        case target[:type]
        when "entity_id"
          resolver = context[:resolve_entity]
          entity = resolver&.call(mention[:kind], target[:id]) if resolver
        when "urn"
          entity = nil
        end

        if entity
          { status: "resolved", kind: mention[:kind],
            entity: entity, label: mention[:label] }
        else
          unresolved(mention)
        end
      end
      private_class_method :resolve_entity

      def resolve_bib(mention, context)
        target = mention[:target]
        entry = context[:resolve_bib_entry]&.call(target[:id])

        if entry
          { status: "resolved", kind: "bib",
            entry: entry, label: mention[:label] }
        else
          unresolved(mention)
        end
      end
      private_class_method :resolve_bib

      def resolve_image(mention)
        target = mention[:target]
        if target[:type] == "url"
          { status: "external_image", kind: "image",
            url: target[:url], label: mention[:label] }
        else
          { status: "local_image", kind: "image",
            path: target[:path], label: mention[:label] }
        end
      end
      private_class_method :resolve_image

      def lookup_concept(target, context)
        resolver = context[:resolve_concept]
        return nil unless resolver

        case target[:type]
        when "dataset_qualified"
          resolver.call(dataset: target[:dataset], id: target[:id])
        when "urn"
          resolver.call(urn: target[:urn])
        end
      end
      private_class_method :lookup_concept

      def find_matching_source(target, concept)
        sources = concept.respond_to?(:data) ? concept.data&.sources : concept.sources
        return nil unless sources

        case target[:type]
        when "dataset_qualified"
          sources.find do |s|
            next unless s.respond_to?(:origin) && s.origin.respond_to?(:ref)
            ref = s.origin.ref
            ref && ref.source == target[:dataset] && ref.id == target[:id]
          end
        when "urn"
          nil
        end
      end
      private_class_method :find_matching_source

      def unresolved(mention)
        { status: "unresolved", kind: mention[:kind],
          target: mention[:target], label: mention[:label] }
      end
      private_class_method :unresolved
    end
  end
end
