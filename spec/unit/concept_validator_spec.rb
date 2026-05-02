# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::ConceptValidator do
  def write_concept(dir, name, content)
    File.write(File.join(dir, name), YAML.dump(content))
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
    base.merge(overrides) do |_key, oldval, newval|
      if oldval.is_a?(Hash) && newval.is_a?(Hash)
        oldval.merge(newval)
      else
        newval
      end
    end
  end

  describe "#validate_all" do
    it "returns valid for canonical concepts" do
      Dir.mktmpdir do |dir|
        write_concept(dir, "1.yaml", valid_concept)
        result = described_class.new(dir).validate_all
        expect(result).to be_valid
      end
    end

    it "reports missing termid" do
      Dir.mktmpdir do |dir|
        concept = valid_concept
        concept = concept.reject { |k, _| k == "termid" }
        write_concept(dir, "bad.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/missing termid/))
      end
    end

    it "reports non-string termid" do
      Dir.mktmpdir do |dir|
        write_concept(dir, "1.yaml", valid_concept.merge("termid" => 123))
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/termid must be a string/))
      end
    end

    it "reports duplicate termids" do
      Dir.mktmpdir do |dir|
        write_concept(dir, "a.yaml", valid_concept)
        write_concept(dir, "b.yaml", valid_concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/duplicate termid '1'/))
      end
    end

    it "reports bare string definition" do
      Dir.mktmpdir do |dir|
        concept = valid_concept
        concept["eng"] = concept["eng"].merge("definition" => "bare string")
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/definition is bare string/))
      end
    end

    it "reports authoritative_source" do
      Dir.mktmpdir do |dir|
        concept = valid_concept
        concept["eng"] =
          concept["eng"].merge("authoritative_source" => { "ref" => "ISO 9000" })
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/has 'authoritative_source'/))
      end
    end

    it "reports invalid entry_status" do
      Dir.mktmpdir do |dir|
        concept = valid_concept
        concept["eng"] = concept["eng"].merge("entry_status" => "Standard")
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/invalid entry_status 'Standard'/))
      end
    end

    it "reports abbrev: true in terms" do
      Dir.mktmpdir do |dir|
        concept = valid_concept
        concept["eng"] =
          concept["eng"].merge("terms" => [{ "designation" => "GIS",
                                             "abbrev" => true }])
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/has 'abbrev: true'/))
      end
    end

    it "warns about _revisions" do
      Dir.mktmpdir do |dir|
        concept = valid_concept.merge("_revisions" => [{ "date" => "2020" }])
        write_concept(dir, "1.yaml", concept)
        result = described_class.new(dir).validate_all
        expect(result.warnings).to include(a_string_matching(/has '_revisions'/))
        expect(result).to be_valid
      end
    end

    it "reports no language blocks" do
      Dir.mktmpdir do |dir|
        write_concept(dir, "1.yaml", { "termid" => "1" })
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/no language blocks/))
      end
    end

    it "reports YAML parse errors" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "bad.yaml"), "termid: [\ninvalid yaml")
        result = described_class.new(dir).validate_all
        expect(result.errors).to include(a_string_matching(/YAML parse error/))
      end
    end
  end
end
