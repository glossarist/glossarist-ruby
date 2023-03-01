# frozen_string_literal: true

RSpec.describe Glossarist::ConceptSet do
  subject do
    described_class.new(
      concepts,
      assets,
      bibliography: { local_cache: fixtures_path("relaton_cache") },
    )
  end

  let(:concepts) { fixtures_path("concept_collection") }

  let(:assets) do
    [
      Glossarist::Asset.new("some/random/path"),
      Glossarist::Asset.new("some/random/path/2"),
      Glossarist::Asset.new("another/random/path"),
    ]
  end

  describe "#to_latex" do
    context "when file name is not given" do
      let(:expected_output) do
        <<~LATEX_OUTPUT
          \\newglossaryentry{biological-entity}
          {
          name={biological\\_entity}
          description={\\textbf{\\gls{material entity}} that was or is a living organism}
          }

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

          \\newglossaryentry{material entity}
          {
          name={material entity}
          description={\\textbf{\\gls{entity}} that occupies three-dimensional space}
          }

          \\newglossaryentry{non-biological entity}
          {
          name={non-biological entity}
          description={\\textbf{\\gls{material entity}} that is not and has never been a living organism}
          }

          \\newglossaryentry{person}
          {
          name={person}
          description={\\textbf{\\gls{biological-entity}} that is a human being}
          }
        LATEX_OUTPUT
      end

      it "should generate correct latex output" do
        expect(subject.to_latex.split("\n\n").sort).to eq(expected_output.split("\n\n"))
      end
    end

    context "when filename is given" do
      let(:filename) { fixtures_path("latex_entries.txt") }

      it "should call the `to_latex_from_file` method" do
        expect(subject).to receive(:to_latex_from_file).with(filename)
        subject.to_latex(filename)
      end
    end
  end

  describe "#to_latex_from_file" do
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
      expect(subject.send(:to_latex_from_file, fixtures_path("latex_entries.txt"))).to eq(expected_output)
    end

    it "should display the name of the concept if it is not found" do
      expect do
        subject.send(:to_latex_from_file, fixtures_path("latex_entries.txt"))
      end.to output("  [Not Found]: random_text\n").to_stdout
    end
  end

  describe "#latex_template" do
    let(:expected_output) do
      <<~LATEX_OUTPUT
        \\newglossaryentry{immaterial-entity}
        {
        name={immaterial\\_entity}
        description={\\textbf{\\gls{entity}} that does not occupy three-dimensional space}
        }
      LATEX_OUTPUT
    end

    let(:concept) { subject.concepts.fetch("3.1.1.2") }

    it "should output correct latex" do
      expect(subject.send(:latex_template, concept)).to eq(expected_output)
    end
  end

  describe "#normalize_definition" do
    let(:definition) { "definition with {{reference}} to another definition." }

    let(:expected_definition) do
      "definition with \\textbf{\\gls{reference}} to another definition."
    end

    it "should convert the definition to latex format" do
      expect(subject.send(:normalize_definition, definition)).to eq(expected_definition)
    end
  end
end
