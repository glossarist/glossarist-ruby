# frozen_string_literal: true

require "rdf/turtle"

# Extends Lutaml::Turtle::Transform to handle:
# - Multiple rdf:type values (types method)
# - URI-valued predicates (as: :uri)
# - Reference-only members (inline: false)
# - Linking predicates for members (link option)
# - Recursive prefix collection
# - Polymorphic member collections
module Lutaml
  module Turtle
    class Transform < Lutaml::Rdf::Transform
      def model_to_data(instance, _format, options = {})
        mapping = extract_turtle_mapping(options)
        return "" unless mapping

        if !mapping.rdf_subject && mapping.has_types_or_predicates? && mapping.rdf_members.empty?
          raise MissingSubjectError,
                "Turtle mapping requires a subject block"
        end

        graph = build_graph(mapping, instance)
        return "" if graph.empty?

        prefixes = collect_all_prefixes(mapping, instance)
        RDF::Turtle::Writer.buffer(prefixes: prefixes) do |writer|
          graph.each_statement { |stmt| writer << stmt }
        end.strip
      end

      def data_to_model(data, _format, options = {})
        mapping = extract_turtle_mapping(options)
        unless mapping&.rdf_subject
          raise MissingSubjectError,
                "Turtle mapping requires a subject block"
        end

        graph = data.is_a?(RDF::Graph) ? data : Lutaml::Turtle::Adapter.parse(data)
        attrs = extract_attributes(graph, mapping)
        build_instance(attrs, options)
      end

      private

      def extract_turtle_mapping(options)
        options[:mappings] || mappings_for(:turtle, lutaml_register)
      end

      def build_graph(mapping, instance)
        graph = RDF::Graph.new

        if mapping.has_types_or_predicates?
          subject_uri = if mapping.rdf_subject
                          RDF::URI(resolve_subject_uri(mapping, instance))
                        else
                          RDF::Node.new
                        end

          emit_type_statements(graph, subject_uri, mapping)
          emit_predicate_statements(graph, subject_uri, instance, mapping)
          emit_member_link_statements(graph, subject_uri, instance, mapping)
          emit_relationship_statements(graph, subject_uri, instance)
        end

        emit_child_resources(graph, instance, mapping)

        graph
      end

      def emit_type_statements(graph, subject_uri, mapping)
        mapping.rdf_types.each do |type_str|
          type_uri = RDF::URI(mapping.namespace_set.resolve_compact_iri(type_str))
          graph << RDF::Statement.new(subject_uri, RDF.type, type_uri)
        end
      end

      def emit_predicate_statements(graph, subject_uri, instance, mapping)
        mapping.rdf_predicates.each do |rule|
          value = instance.public_send(rule.to)
          next if value.nil?

          Array(value).each do |v|
            next if v.is_a?(String) && v.empty?

            object = build_rdf_object(v, rule, mapping)
            graph << RDF::Statement.new(subject_uri, RDF::URI(rule.uri), object)
          end
        end
      end

      def emit_member_link_statements(graph, subject_uri, instance, mapping)
        mapping.rdf_members.each do |member_rule|
          next unless member_rule.link

          collection = Array(instance.public_send(member_rule.attr_name))
          collection.each do |member|
            child_mapping = member.class.mappings[:turtle]
            next unless child_mapping&.rdf_subject

            child_uri = RDF::URI(resolve_subject_uri(child_mapping, member))
            link_uri = RDF::URI(member_rule.link_predicate_for(member, mapping))
            next unless link_uri

            graph << RDF::Statement.new(subject_uri, link_uri, child_uri)
          end
        end
      end

      def emit_relationship_statements(graph, subject_uri, instance)
        return unless instance.is_a?(Glossarist::Rdf::Relationships)

        Array(instance.relationship_triples).each do |pred_uri, obj_uri|
          graph << RDF::Statement.new(subject_uri, RDF::URI(pred_uri), RDF::URI(obj_uri))
        end
      end

      def emit_child_resources(graph, instance, mapping)
        mapping.rdf_members.each do |member_rule|
          collection = Array(instance.public_send(member_rule.attr_name))
          collection.each do |member|
            member_mapping = member.class.mappings[:turtle]
            next unless member_mapping

            graph << build_graph(member_mapping, member)
          end
        end
      end

      def build_rdf_object(value, rule, mapping = nil)
        if rule.uri_value?
          resolved = if mapping && value.include?(":")
                       mapping.namespace_set.resolve_compact_iri(value)
                     else
                       value
                     end
          RDF::URI(resolved)
        elsif rule.lang_tagged
          lang = extract_language(value)
          RDF::Literal.new(value.to_s, language: lang)
        else
          case value
          when Integer then RDF::Literal.new(value, datatype: RDF::XSD.integer)
          when Float then RDF::Literal.new(value, datatype: RDF::XSD.double)
          when TrueClass, FalseClass then RDF::Literal.new(value, datatype: RDF::XSD.boolean)
          else RDF::Literal.new(value.to_s)
          end
        end
      end

      def collect_all_prefixes(mapping, instance)
        ns_set = collect_namespaces_recursive(mapping, instance)
        ns_set.each.with_object({}) do |ns, h|
          h[ns.prefix.to_sym] = ns.uri if ns.prefix && ns.uri
        end
      end

      def collect_namespaces_recursive(mapping, instance)
        ns_set = mapping.namespace_set

        mapping.rdf_members.each do |member_rule|
          collection = Array(instance.public_send(member_rule.attr_name))
          next if collection.empty?

          collection.map(&:class).uniq.each do |klass|
            member_mapping = klass.mappings[:turtle]
            next unless member_mapping

            ns_set = ns_set.merge(member_mapping.namespace_set)
            # Recurse into child members
            child_ns = collect_namespaces_recursive(member_mapping, collection.first)
            ns_set = ns_set.merge(child_ns)
          end
        end

        ns_set
      end

      def extract_attributes(graph, mapping)
        attrs = {}
        first_type_uri = mapping.rdf_types.first
        return attrs unless first_type_uri

        type_uri = RDF::URI(mapping.namespace_set.resolve_compact_iri(first_type_uri))
        matching_subjects = find_subjects_by_type(graph, type_uri)

        matching_subjects.each do |subject|
          mapping.rdf_predicates.each do |rule|
            stmts = graph.query([subject, RDF::URI(rule.uri), nil])
            next if stmts.empty?

            values = stmts.map do |s|
              rule.uri_value? ? s.object.to_s : literal_to_ruby(s.object)
            end
            attrs[rule.to] = values.length == 1 ? values.first : values
          end
        end

        attrs
      end

      def find_subjects_by_type(graph, type_uri)
        graph.query([nil, RDF.type, RDF::URI(type_uri)]).map(&:subject).uniq
      end

      def literal_to_ruby(rdf_object)
        case rdf_object
        when RDF::Literal
          case rdf_object.datatype
          when RDF::XSD.integer then rdf_object.value.to_i
          when RDF::XSD.double, RDF::XSD.decimal, RDF::XSD.float then rdf_object.value.to_f
          when RDF::XSD.boolean then rdf_object.value == "true"
          else rdf_object.value
          end
        else
          rdf_object.to_s
        end
      end
    end
  end
end
