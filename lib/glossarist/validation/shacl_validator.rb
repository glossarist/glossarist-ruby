# frozen_string_literal: true

require "rdf/turtle"
require "shacl"
require "pathname"

module Glossarist
  module Validation
    # Validates Turtle output against SHACL shapes.
    #
    # Shapes resolution order:
    #   1. Explicit :shapes_path option
    #   2. Glossarist::ConceptModel.path("ontologies/shapes/glossarist.shacl.ttl")
    #      (when the concept-model gem is available)
    #   3. Repo-relative fallback (development only)
    class ShaclValidator
      DEFAULT_SHAPES_PATHS = [
        "ontologies/shapes/glossarist.shacl.ttl",
        "concept-model/ontologies/shapes/glossarist.shacl.ttl",
        "../concept-model/ontologies/shapes/glossarist.shacl.ttl",
      ].freeze

      attr_reader :shapes_path

      def initialize(shapes_path: nil)
        @shapes_path = shapes_path || self.class.default_shapes_path
      end

      def validate_files(paths)
        validate_graphs(Array(paths).map { |p| load_graph(p) })
      end

      def validate_graphs(graphs)
        shapes = SHACL::Shapes.from_graph(load_graph(@shapes_path))
        failures = []

        graphs.each do |graph|
          report = shapes.execute(graph)
          next if report.conform?

          failures << Report.new(results: report.results)
        end

        AggregateReport.new(failures: failures)
      end

      class << self
        def default_shapes_path
          if defined?(::Glossarist::ConceptModel) &&
             ::Glossarist::ConceptModel.respond_to?(:path)
            ::Glossarist::ConceptModel
              .path("ontologies/shapes/glossarist.shacl.ttl")
          else
            resolve_fallback_path
          end
        end

        private

        def resolve_fallback_path
          DEFAULT_SHAPES_PATHS.each do |rel|
            path = File.expand_path(rel, Dir.pwd)
            return path if File.exist?(path)
          end
          raise ArgumentError,
                "No SHACL shapes path provided and concept-model gem not " \
                "available. Pass shapes: '/path/to/glossarist.shacl.ttl'."
        end
      end

      private

      def load_graph(path)
        return path if path.is_a?(RDF::Graph)

        graph = RDF::Graph.new
        RDF::Turtle::Reader.new(File.read(path)) do |reader|
          reader.each_statement { |stmt| graph << stmt }
        end
        graph
      end
    end

    Report = Struct.new(:results, keyword_init: true) do
      def conformant?
        results.empty?
      end

      def to_s
        "  #{results.length} violation(s)"
      end
    end

    AggregateReport = Struct.new(:failures, keyword_init: true) do
      def conformant?
        failures.empty?
      end

      def to_s
        lines = ["SHACL validation failed: #{failures.length} file(s) with violations"]
        failures.each do |failure|
          lines << failure.to_s
          failure.results.each do |result|
            lines << "    #{result.path}: #{result.message}"
          end
        end
        lines.join("\n")
      end
    end
  end
end
