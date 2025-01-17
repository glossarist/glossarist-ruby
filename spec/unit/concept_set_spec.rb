# frozen_string_literal: true

RSpec.describe Glossarist::ConceptSet do
  subject do
    described_class.new(
      concepts,
      assets,
      bibliography: { local_cache: fixtures_path("relaton_cache") },
    )
  end

  let(:concepts) { fixtures_path("concept_collection_v2") }

  let(:assets) do
    [
      Glossarist::Asset.new({ path: "some/random/path" }),
      Glossarist::Asset.new({ path: "some/random/path/2" }),
      Glossarist::Asset.new({ path: "another/random/path" }),
    ]
  end

  describe "#to_latex" do
    context "when file name is not given" do
      let(:expected_output) do
        <<~LATEX_OUTPUT
          \\newglossaryentry{geodetic latitude}
          {
          name={geodetic latitude}
          description={angle from the equatorial plane to the perpendicular to the ellipsoid through a given point, northwards treated as positive}
          }

          \\newglossaryentry{intension}
          {
          name={intension}
          description={set of characteristics which makes up the concept}
          }

          \\newglossaryentry{Cartesian coordinate system}
          {
          name={Cartesian coordinate system}
          description={coordinate system which gives the position of points relative to n mutually perpendicular axes that each has zero curvature}
          }

          \\newglossaryentry{component}
          {
          name={component}
          description={constituent part of a postal address}
          }
        LATEX_OUTPUT
      end

      it "should generate correct latex output" do
        expect(subject.to_latex.split("\n\n").sort.map(&:strip)).to eq(expected_output.split("\n\n").sort.map(&:strip))
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
        \\newglossaryentry{geodetic latitude}
        {
        name={geodetic latitude}
        description={angle from the equatorial plane to the perpendicular to the ellipsoid through a given point, northwards treated as positive}
        }

        \\newglossaryentry{intension}
        {
        name={intension}
        description={set of characteristics which makes up the concept}
        }

        \\newglossaryentry{Cartesian coordinate system}
        {
        name={Cartesian coordinate system}
        description={coordinate system which gives the position of points relative to n mutually perpendicular axes that each has zero curvature}
        }
      LATEX_OUTPUT
    end

    it "should generate correct latex output" do
      expect(subject.send(:to_latex_from_file,
                          fixtures_path("latex_entries.txt"))).to eq(expected_output)
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
        \\newglossaryentry{geodetic latitude}
        {
        name={geodetic latitude}
        description={angle from the equatorial plane to the perpendicular to the ellipsoid through a given point, northwards treated as positive}
        }
      LATEX_OUTPUT
    end

    let(:concept) { subject.concepts.fetch("200") }

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
      expect(subject.send(:normalize_definition,
                          definition)).to eq(expected_definition)
    end
  end
end
