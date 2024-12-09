require_relative "grammar_info"

module Glossarist
  module LutamlModel
    class Expression < Base
      attribute :prefix, :string
      attribute :usage_info, :string
      attribute :grammar_info, GrammarInfo
      attribute :type, :string, default: -> { "expression" }

      yaml do
        map :prefix, to: :prefix
        map :usage_info, to: :usage_info
        map :grammar_info, to: :grammar_info
        map :type, to: :type, render_default: true
      end
    end
  end
end
