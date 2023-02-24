# frozen_string_literal: true

RSpec.describe Glossarist::ConceptSet do
  subject do
    described_class.new(
      concepts,
      assets,
      bibliography: { local_cache: fixtures_path("relaton_cache") },
    )
  end

  let(:assets) do
    [
      Glossarist::Asset.new("some/random/path"),
      Glossarist::Asset.new("some/random/path/2"),
      Glossarist::Asset.new("another/random/path"),
    ]
  end

  describe "#to_latex" do
    let(:concepts) { fixtures_path("concept_collection") }

    let(:expected_output) do
      <<~LATEX_OUTPUT
        \\newglossaryentry{entity}
        {
        name={entity}
        description={concrete or abstract thing that exists, did exist, or can possibly exist, including associations among these things}
        }

        \\newglossaryentry{immaterial-entity}
        {
        name={immaterial\\_entity}
        description={\\textbf{\\gls{entity}} that does not occupy three-dimensional space}
        }

        \\newglossaryentry{person}
        {
        name={person}
        description={\\textbf{\\gls{biological-entity}} that is a human being}
        }
      LATEX_OUTPUT
    end

    it "should generate correct latex output" do
      expect(subject.to_latex(fixtures_path("latex_entries.txt"))).to eq(expected_output)
    end
  end
end
