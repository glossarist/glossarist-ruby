# frozen_string_literal: true

require_relative "../../support/shared_examples/enum"
require_relative "../../support/shared_examples/boolean_attributes"

RSpec.describe Glossarist::Designation::GrammarInfo do
  it_behaves_like "an Enum"
  it_behaves_like "having Boolean attributes",
                  Glossarist::GlossaryDefinition::GRAMMAR_INFO_BOOLEAN_ATTRIBUTES

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

      {
        "preposition" => true,
        "participle" => false,
        "adj" => false,
        "verb" => false,
        "adverb" => false,
        "noun" => false,
        "gender" => %w[m],
        "number" => %w[singular plural],
      }

      retval = described_class.from_yaml(grammar_info.to_yaml)
      expect(retval.preposition).to eq(true)
      expect(retval.participle).to eq(false)
      expect(retval.adj).to eq(false)
      expect(retval.verb).to eq(false)
      expect(retval.adverb).to eq(false)
      expect(retval.noun).to eq(false)
      expect(retval.gender).to eq(%w[m])
      expect(retval.number).to eq(%w[singular plural])
    end
  end
end
