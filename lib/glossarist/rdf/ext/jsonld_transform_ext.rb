# frozen_string_literal: true

require "json"

# Extends Lutaml::JsonLd::Transform to handle:
# - Multiple rdf:type values
# - URI-valued predicates (as: :uri)
# - Linking predicates for members (link option)
# - Recursive context/namespace collection
# - Recursive graph document building
module Lutaml
  module JsonLd
    class Transform < Lutaml::Rdf::Transform
      def model_to_data(instance, _format, options = {})
        mapping = extract_mapping(options)
        return {} unless mapping

        if mapping.rdf_members.any?
          build_graph_document(mapping, instance)
        else
          build_resource_object(mapping, instance)
        end
      end

      def data_to_model(data, _format, options = {})
        mapping = extract_mapping(options)
        return model_class.new unless mapping

        hash = data.is_a?(String) ? JSON.parse(data) : data

        if hash.key?("@graph") && hash["@graph"].is_a?(Array) && !hash["@graph"].empty?
          graph_data = hash["@graph"]
          first = graph_data.first
          hash = first.is_a?(Hash) ? first : {}
        end

        hash = strip_jsonld_keywords(hash)

        attrs = {}
        mapping.rdf_predicates.each do |rule|
          value = hash[rule.predicate_name]
          next if value.nil?

          attrs[rule.to] = if rule.lang_tagged && value.is_a?(Hash)
                             flatten_language_map(value)
                           else
                             value
                           end
        end

        build_instance(attrs, options)
      end

      private

      def extract_mapping(options)
        options[:mappings] || mappings_for(:jsonld, lutaml_register)
      end

      def build_graph_document(mapping, instance)
        context = build_merged_context_recursive(mapping, instance)
        graph = collect_resources(mapping, instance)

        { "@context" => context, "@graph" => graph }
      end

      def collect_resources(mapping, instance)
        graph = []

        if mapping.rdf_subject
          resource = build_resource_data(mapping, instance)
          graph << resource unless resource.empty?
        end

        mapping.rdf_members.each do |member_rule|
          collection = Array(instance.public_send(member_rule.attr_name))
          collection.each do |member|
            member_mapping = member.class.mappings[:jsonld]
            next unless member_mapping

            resource = build_resource_data(member_mapping, member)
            graph << resource unless resource.empty?

            # Recurse into child members
            child_resources = collect_resources(member_mapping, member)
            # Skip the first entry (already added above) and any empty resources
            child_resources[1..-1].each { |r| graph << r }
          end
        end

        graph
      end

      def build_merged_context_recursive(mapping, instance)
        context_hash = build_context_from_mapping(mapping).to_hash

        mapping.rdf_members.each do |member_rule|
          collection = Array(instance.public_send(member_rule.attr_name))
          next if collection.empty?

          collection.map(&:class).uniq.each do |klass|
            member_mapping = klass.mappings[:jsonld]
            next unless member_mapping

            context_hash.merge!(build_context_from_mapping(member_mapping).to_hash)

            # Recurse into child members
            child_ctx = build_merged_context_recursive(member_mapping, collection.first)
            context_hash.merge!(child_ctx)
          end
        end

        context_hash
      end

      def build_context_from_mapping(mapping)
        context = Context.new
        mapping.namespace_set.each { |ns| context.prefix(ns) }
        mapping.rdf_predicates.each do |pred|
          if pred.lang_tagged
            context.term(pred.predicate_name,
                         id: pred.uri,
                         container: :language)
          else
            context.term(pred.predicate_name, id: pred.uri)
          end
        end
        context
      end

      def build_resource_object(mapping, instance)
        context = build_context_from_mapping(mapping).to_hash
        data = build_resource_data(mapping, instance)
        { "@context" => context }.merge(data)
      end

      def build_resource_data(mapping, instance)
        result = {}

        if mapping.rdf_types.any?
          types = mapping.rdf_types.map do |t|
            mapping.namespace_set.resolve_compact_iri(t)
          end
          result["@type"] = types.length == 1 ? types.first : types
        end

        if mapping.rdf_subject
          result["@id"] = resolve_subject_uri(mapping, instance)
        end

        mapping.rdf_predicates.each do |rule|
          value = instance.public_send(rule.to)
          next if value.nil?
          next if value.is_a?(String) && value.empty?

          result[rule.predicate_name] = if rule.lang_tagged
                                          build_language_map(value)
                                        else
                                          serialize_rdf_value(value, rule, mapping)
                                        end
        end

        # Emit variable-predicate relationship triples
        if instance.is_a?(Glossarist::Rdf::Relationships)
          Array(instance.relationship_triples).each do |pred_uri, obj_uri|
            key = pred_uri.split("#").last.split("/").last
            result[key] = { "@id" => obj_uri }
          end
        end

        result
      end

      def build_language_map(values)
        case values
        when Array
          map = {}
          values.each do |v|
            lang = extract_language(v)
            map[lang] = v.to_s if lang
          end
          map.empty? ? nil : map
        else
          lang = extract_language(values)
          lang ? { lang => values.to_s } : values.to_s
        end
      end

      def flatten_language_map(lang_map)
        lang_map.values
      end

      def serialize_rdf_value(value, rule = nil, mapping = nil)
        case value
        when Array then value.map { |v| serialize_rdf_value(v, rule, mapping) }
        when Integer, Float, TrueClass, FalseClass then value
        else value.to_s
        end
      end

      def strip_jsonld_keywords(data)
        return data unless data.is_a?(Hash)

        data.reject { |key, _| key.start_with?("@") }
      end
    end
  end
end
