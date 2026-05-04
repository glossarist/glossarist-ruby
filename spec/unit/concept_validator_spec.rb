# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::ConceptValidator do
  def write_concept(dir, name, content)
    concepts_dir = File.join(dir, "concepts")
    FileUtils.mkdir_p(concepts_dir)
    File.write(File.join(concepts_dir, name), YAML.dump(content))
  end

  def valid_concept(overrides = {})
    base = {
      "termid" => "1",
      "eng" => {
        "terms" => [{ "type" => "expression", "designation" => "test" }],
        "definition" => [{ "content" => "a definition" }],
        "entry_status" => "valid",
      },
    }
    overrides.each do |key, value|
      base[key] = if base[key].is_a?(Hash) && value.is_a?(Hash)
                    base[key].merge(value)
                  else
                    value
                  end
    end
    base
  end

  describe "#validate_all" do
    it "returns valid for canonical concepts" do
      Dir.mktmpdir do |dir|
        write_concept(dir, "1.yaml", valid_concept)
        result = described_class.new(dir).validate_all
        expect(result).to be_valid
      end
    end

    it "reports duplicate ids" do
      Dir.mktmpdir do |dir|
        write_concept(dir, "a.yaml", valid_concept)
        write_concept(dir, "b.yaml", valid_concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/duplicate id '1'/))
      end
    end

    it "reports invalid entry_status" do
      Dir.mktmpdir do |dir|
        concept = valid_concept(
          "eng" => {
            "terms" => [{ "type" => "expression", "designation" => "test" }],
            "definition" => [{ "content" => "a definition" }],
            "entry_status" => "Standard",
          },
        )
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/invalid entry_status 'Standard'/))
      end
    end

    it "reports no localizations" do
      Dir.mktmpdir do |dir|
        write_concept(dir, "1.yaml", { "termid" => "1" })
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/no localizations/))
      end
    end

    it "reports missing terms" do
      Dir.mktmpdir do |dir|
        concept = {
          "termid" => "1",
          "eng" => {
            "definition" => [{ "content" => "a definition" }],
            "entry_status" => "valid",
          },
        }
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/must have at least 1 term/))
      end
    end

    it "reports empty definition" do
      Dir.mktmpdir do |dir|
        concept = valid_concept(
          "eng" => {
            "terms" => [{ "type" => "expression", "designation" => "test" }],
            "definition" => [],
            "entry_status" => "valid",
          },
        )
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/definition is empty/))
      end
    end
  end
end
