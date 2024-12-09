# frozen_string_literal: true

require_relative "../../support/shared_examples/enum"
require_relative "../../support/shared_examples/boolean_attributes"

RSpec.describe Glossarist::LutamlModel::GrammarInfo do
  # it_behaves_like "an Enum"
  # it_behaves_like "having Boolean attributes", Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES

  describe "#to_yaml" do
    it "will convert to a hash" do
      grammar_info = described_class.new({
        "preposition" => true,
        "participle" => false,
        "adj" => false,
        "verb" => false,
        "adverb" => false,
        "noun" => false,
        "gender" => %w[m],
        "number" => %w[singular plural],
      })

      expected_yaml = <<~YAML
        ---
        gender:
        - m
        number:
        - singular
        - plural
        preposition: 'true'
        participle: 'false'
        adj: 'false'
        verb: 'false'
        adverb: 'false'
        noun: 'false'
      YAML

      expect(grammar_info.to_yaml).to eq(expected_yaml)
    end
  end
end
