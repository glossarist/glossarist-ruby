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
    #   2. Vendored shapes at data/concept-model/shapes/glossarist.shacl.ttl
    #      (shipped with the gem, relative to the gem root)
    class ShaclValidator
      VENDORED_SHAPES_PATH =
        File.expand_path(
          "../../../data/concept-model/shapes/glossarist.shacl.ttl",
          __dir__
        ).freeze

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
          return VENDORED_SHAPES_PATH if File.exist?(VENDORED_SHAPES_PATH)

          raise ArgumentError,
                "No SHACL shapes path provided and the vendored shapes " \
                "file (#{VENDORED_SHAPES_PATH}) is missing. Pass " \
                "shapes_path: '/path/to/glossarist.shacl.ttl'."
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
