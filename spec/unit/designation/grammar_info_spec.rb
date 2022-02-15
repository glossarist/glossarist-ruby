# frozen_string_literal: true

require_relative "../../support/shared_examples/enum"
require_relative "../../support/shared_examples/boolean_attributes"

RSpec.describe Glossarist::Designation::GrammarInfo do
  it_behaves_like "an Enum"
  it_behaves_like "having Boolean attributes", described_class::BOOLEAN_ATTRIBUTES

  describe "#to_h" do
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

      expected_hash = {
        "preposition" => true,
        "participle" => false,
        "adj" => false,
        "verb" => false,
        "adverb" => false,
        "noun" => false,
        "gender" => %i[m],
        "number" => %i[singular plural],
      }

      expect(grammar_info.to_h).to eq(expected_hash)
    end
  end
end
