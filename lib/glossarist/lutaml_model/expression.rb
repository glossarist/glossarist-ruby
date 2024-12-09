module Glossarist
  module LutamlModel
    class Expression < Lutaml::Model::Serializable
      attribute :prefix, :string
      attribute :usage_info, :string
      attribute :grammer_info, GrammerInfo

      yaml do
        map :prefix, to: :prefix
        map :usage_info, to: :usage_info
        map :grammer_info, to: :grammer_info
      end

      def grammar_info=(grammar_info)
        @grammar_info = grammar_info.map { |g| GrammarInfo.new(g) }
      end
    end
  end
end
