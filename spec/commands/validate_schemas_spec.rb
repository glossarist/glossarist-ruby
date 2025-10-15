# frozen_string_literal: true

require "glossarist/cli"

RSpec.describe Glossarist::Commands::ValidateSchemas do
  subject(:test_subject) { described_class.new(options).run }

  let(:test_output_path) do
    File.expand_path("reports.txt", __dir__)
  end

  let(:schema_path) do
    File.expand_path("../fixtures/validate_schemas/schemas/v2", __dir__)
  end

  let(:remote_schema_path) do
    "https://github.com/glossarist/concept-model/raw/" \
    "22537b0884aa8982097e552eb87e66c26d6be5dc/schemas/v2"
  end

  let(:options) do
    {
      concept_path: new_glossary_path,
      schema_path: schema_path,
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
      File.expand_path("../fixtures/validate_schemas/new", __dir__)
    end

    let(:expected_report) do
      File.expand_path(
        "../fixtures/validate_schemas/valid_report.txt",
        __dir__,
      )
    end

    context "against local schemas" do
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

    context "against remote schemas" do
      let(:options) do
        {
          concept_path: new_glossary_path,
          schema_path: remote_schema_path,
          report_path: test_output_path,
        }
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
  end

  context "when concept file contains validation errors" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_schemas/new_invalid", __dir__)
    end

    let(:expected_report) do
      File.expand_path(
        "../fixtures/validate_schemas/invalid_report.txt",
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
          "The property '#/data/language_code' was not of a maximum string " \
          "length of 3",
        ),
      ).to be true
      expect(
        output.include?(
          "The property '#/data/sources/0/type' value \"invalid_type\" did " \
          "not match one of the following values: authoritative",
        ),
      ).to be true
      expect(output).to eq(expected_output)
    end
  end

  context "when concept file is invalid" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_schemas/invalid_concept", __dir__)
    end

    it "raise error" do
      expect { test_subject }
        .to raise_error(RuntimeError, /Invalid Concept v2 YAML/)
    end
  end


  context "when load schema cannot be loaded" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_schemas/new", __dir__)
    end

    let(:options) do
      {
        concept_path: new_glossary_path,
        schema_path: "invalid_schema_path",
        report_path: test_output_path,
      }
    end

    it "raise error" do
      expect { test_subject }.to raise_error(Errno::ENOENT)
    end
  end

  context "when remote schema cannot be loaded" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_schemas/new", __dir__)
    end

    let(:options) do
      {
        concept_path: new_glossary_path,
        schema_path: "https://github.com/glossarist/concept-model/invalid",
        report_path: test_output_path,
      }
    end

    it "raise error" do
      expect { test_subject }.to raise_error(OpenURI::HTTPError)
    end
  end

  context "when validate concept file in tc211" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_schemas/tc211", __dir__)
    end

    let(:expected_report) do
      File.expand_path("../fixtures/validate_schemas/tc211.txt", __dir__)
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

  context "when validate concept file in tc204" do
    let(:new_glossary_path) do
      File.expand_path("../fixtures/validate_schemas/tc204", __dir__)
    end

    let(:expected_report) do
      File.expand_path("../fixtures/validate_schemas/tc204.txt", __dir__)
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
end
