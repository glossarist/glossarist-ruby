# frozen_string_literal: true

require_relative "../../support/shared_examples/enum"
require_relative "../../support/shared_examples/boolean_attributes"

RSpec.describe Glossarist::Designation::GrammarInfo do
  it_behaves_like "an Enum"
  it_behaves_like "having Boolean attributes", Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES

  describe "#to_yaml" do
    it "will convert to a yaml" do
      grammar_info = described_class.from_yaml({
        "preposition" => true,
        "participle" => false,
        "adj" => false,
        "verb" => false,
        "adverb" => false,
        "noun" => false,
        "gender" => %w[m],
        "number" => %w[singular plural],
      }.to_yaml)

      expected_yaml = {
        "preposition" => true,
        "participle" => false,
        "adj" => false,
        "verb" => false,
        "adverb" => false,
        "noun" => false,
        "gender" => %w[m],
        "number" => %w[singular plural],
      }

      expect(YAML.load(grammar_info.to_yaml)).to eq(expected_yaml)
    end
  end
end
