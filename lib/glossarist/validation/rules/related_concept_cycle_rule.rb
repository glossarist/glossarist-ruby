# frozen_string_literal: true

module Glossarist
  module Validation
    module Rules
      class RelatedConceptCycleRule < Base
        def code = "GLS-113"
        def category = :references
        def severity = "error"
        def scope = :collection

        DIRECTIONAL = %w[supersedes deprecates narrower].freeze

        def applicable?(context)
          context.concepts.any? { |c| c.related&.any? }
        end

        def check(context)
          graph = build_directed_graph(context.concepts)
          issues = []

          cycles = detect_cycles(graph)
          cycles.each do |cycle|
            path = cycle.join(" -> ")
            issues << issue(
              "Circular relation chain detected: #{path}",
              location: cycle.first,
              suggestion: "Break the cycle by removing or redirecting one of the relations",
            )
          end

          issues
        end

        private

        def build_directed_graph(concepts)
          graph = {}
          concepts.each do |c|
            next unless c.related&.any?

            src_id = c.data&.id&.to_s
            next unless src_id

            c.related.each do |rel|
              next unless DIRECTIONAL.include?(rel.type)

              target_id = resolve_target_id(rel)
              next unless target_id

              (graph[src_id] ||= []) << target_id
            end
          end
          graph
        end

        def resolve_target_id(rel)
          ref = rel.ref
          return nil unless ref

          if ref.is_a?(Glossarist::Citation)
            ref.id || ref.text
          end
        end

        def detect_cycles(graph)
          visited = Set.new
          stack = Set.new
          cycles = []

          graph.keys.each do |node|
            next if visited.include?(node)

            dfs(node, graph, visited, stack, [], cycles)
          end

          cycles
        end

        def dfs(node, graph, visited, stack, path, cycles)
          return if visited.include?(node) && !stack.include?(node)

          if stack.include?(node)
            cycle_start = path.index(node)
            cycles << path[cycle_start..] + [node] if cycle_start
            return
          end

          visited.add(node)
          stack.add(node)
          path = path + [node]

          (graph[node] || []).each do |neighbor|
            dfs(neighbor, graph, visited, stack, path, cycles)
          end

          stack.delete(node)
        end
      end
    end
  end
end
