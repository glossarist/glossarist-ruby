# frozen_string_literal: true

require "glossarist/cli"

RSpec.describe Glossarist::Commands::CompareConcepts do
  subject(:test_subject) { described_class.new(options).run }

  let(:test_output_path) do
    File.expand_path("reports.txt", __dir__)
  end

  let(:old_glossary_path) do
    File.expand_path("../fixtures/compare_concepts/concepts", __dir__)
  end

  let(:options) do
    {
      new_concept_path: new_glossary_path,
      old_concept_path: old_glossary_path,
      report_path: test_output_path,
    }
  end

  before do
    FileUtils.rm_rf(test_output_path)
  end

  after do
    FileUtils.rm_rf(test_output_path)
  end

  context "when concept files are the same" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/compare_concepts/new", __dir__)
    end

    let(:expected_report) do
      File.expand_path(
        "../fixtures/compare_concepts/valid_report.txt",
        __dir__,
      )
    end

    it "outputs the report to the specified path" do
      expect { test_subject }
        .to change { File.exist?(test_output_path) }.from(false).to(true)
    end

    it "outputs report content" do
      test_subject
      output = File.read(test_output_path)
      expected_output = File.read(expected_report)
      expect(output).to eq(expected_output)
    end
  end

  context "when concept files are different" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/compare_concepts/new_diff", __dir__)
    end

    let(:expected_report) do
      File.expand_path(
        "../fixtures/compare_concepts/diff_report.txt",
        __dir__,
      )
    end

    it "outputs the report to the specified path" do
      expect { test_subject }
        .to change { File.exist?(test_output_path) }.from(false).to(true)
    end

    it "reports difference in counts" do
      test_subject
      output = File.read(test_output_path)
      expect(output.include?("No change in concept counts")).to be true
    end

    it "reports difference in mapping" do
      expected_output = <<~OUTPUT
        Aec_service_life_arm.Service_life | Aec_service_life_arm.Service_life
        action_schema.action_resource | action_schema.action_resource
      OUTPUT
      test_subject
      output = File.read(test_output_path)
      expect(output.include?(expected_output)).to be true
    end

    it "reports difference in Diff Tree" do
      expected_diff = <<~DIFF
        Diff Tree of Aec_service_life_arm.Service_life with Similarity score: 93.75%:
        ------------------------------
        └── Glossarist::ManagedConcept
            └── data (Glossarist::ManagedConceptData):
                ├── [1] (Glossarist::ConceptSource)
                │   └── [2] (Glossarist::CustomLocality)
                │       └── value (Lutaml::Model::Type::String):
                │           ├── - (String) "2"
                │           └── + (String) "1"
                └── [1] (Glossarist::Designation::Expression)
                    └── designation (Lutaml::Model::Type::String):
                        ├── - (String) "Aec_service_life"
                        └── + (String) "Service_life"
      DIFF

      test_subject
      output = File.read(test_output_path)
      expected_output = File.read(expected_report)

      expect(output.include?(expected_diff)).to be true
      expect(output).to eq(expected_output)
    end
  end
end
