# frozen_string_literal: true

require "glossarist/cli"

RSpec.describe Glossarist::Commands::ValidateConcepts do
  subject(:test_subject) { described_class.new(options).run }

  let(:test_output_path) do
    File.expand_path("reports.txt", __dir__)
  end

  let(:options) do
    {
      concept_path: new_glossary_path,
      report_path: test_output_path,
    }
  end

  before do
    FileUtils.rm_rf(test_output_path)
  end

  after do
    FileUtils.rm_rf(test_output_path)
  end

  context "when concept file is valid" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_concepts/new", __dir__)
    end

    let(:expected_report) do
      File.expand_path(
        "../fixtures/validate_concepts/valid_report.txt",
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

  context "when invalid concept file provided" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_concepts/new_invalid", __dir__)
    end

    let(:expected_report) do
      File.expand_path(
        "../fixtures/validate_concepts/invalid_report.txt",
        __dir__,
      )
    end

    it "outputs the report to the specified path" do
      expect { test_subject }
        .to change { File.exist?(test_output_path) }.from(false).to(true)
    end

    it "reports validation errors" do
      test_subject
      output = File.read(test_output_path)
      expected_output = File.read(expected_report)
      expect(
        output.include?("Validation errors found:"),
      ).to be true
      expect(
        output.include?(
          "normative_status is `invalid_status`, must be one of the " \
          "following [preferred, deprecated, admitted, <símbolo>, 티에스, " \
          "prąd startowy]",
        ),
      ).to be true
      expect(output).to eq(expected_output)
    end
  end
end
