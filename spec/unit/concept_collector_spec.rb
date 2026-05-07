# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::ConceptCollector do
  before do
    @tmpdir = Dir.mktmpdir
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  def create_v1_dataset(dir, concepts)
    concepts_dir = File.join(dir, "concepts")
    FileUtils.mkdir_p(concepts_dir)
    concepts.each do |c|
      File.write(File.join(concepts_dir, "#{c['termid']}.yaml"), YAML.dump(c))
    end
  end

  def create_v2_grouped_dataset(dir, concepts)
    v2_dir = File.join(dir, "geolexica-v2")
    FileUtils.mkdir_p(v2_dir)
    concepts.each do |mc|
      termid = mc.data.id
      File.write(File.join(v2_dir, "#{termid}.yaml"), mc.to_yaml)
    end
  end

  def create_v2_flat_dataset(dir, concepts)
    concepts_dir = File.join(dir, "concepts")
    FileUtils.mkdir_p(concepts_dir)
    concepts.each do |mc|
      termid = mc.data.id
      parts = ["---\ndata:\n  identifier: \"#{termid}\"\n  localized_concepts:\n"]
      mc.data.localized_concepts.each do |lang, lc_id|
        parts.last << "    #{lang}: #{lc_id}\n"

        l10n = mc.localization(lang)
        next unless l10n

        l10n.uuid = lc_id
        parts << l10n.to_yaml
      end
      File.write(File.join(concepts_dir, "#{termid}.yaml"), parts.join)
    end
  end

  def create_managed_dataset(dir, concepts)
    concept_dir = File.join(dir, "concepts", "concept")
    lc_dir = File.join(dir, "concepts", "localized_concept")
    FileUtils.mkdir_p(concept_dir)
    FileUtils.mkdir_p(lc_dir)

    concepts.each do |mc|
      uuid = SecureRandom.uuid
      lc_map = {}
      mc.localizations.values.each_with_index do |l10n, i|
        lc_uuid = "#{uuid}-#{i}"
        lc_map[l10n.language_code] = lc_uuid
        File.write(File.join(lc_dir, "#{lc_uuid}.yaml"), l10n.to_yaml)
      end
      mc_hash = { "data" => { "identifier" => mc.data.id,
                              "localized_concepts" => lc_map } }
      File.write(File.join(concept_dir, "#{uuid}.yaml"), YAML.dump(mc_hash))
    end
  end

  def build_managed_concept(termid, designation, definition)
    mc = Glossarist::ManagedConcept.new(data: {
                                          id: termid,
                                          localized_concepts: { "eng" => "lc-#{termid}" },
                                        })
    l10n = Glossarist::LocalizedConcept.of_yaml({
                                                  "id" => "lc-#{termid}",
                                                  "data" => {
                                                    "language_code" => "eng",
                                                    "terms" => [{
                                                      "type" => "expression", "designation" => designation
                                                    }],
                                                    "definition" => [{ "content" => definition }],
                                                  },
                                                })
    mc.add_localization(l10n)
    mc
  end

  describe ".collect" do
    it "raises ArgumentError for non-directory" do
      expect { described_class.collect("/nonexistent") }
        .to raise_error(ArgumentError, /not a directory/)
    end

    it "returns empty array for empty directory" do
      expect(described_class.collect(@tmpdir)).to eq([])
    end

    it "collects v1 format concepts" do
      create_v1_dataset(@tmpdir, [
                          { "termid" => "100", "eng" => { "terms" => [{ "type" => "expression", "designation" => "test" }],
                                                          "definition" => [{ "content" => "test def" }] } },
                          { "termid" => "200", "eng" => { "terms" => [{ "type" => "expression", "designation" => "other" }],
                                                          "definition" => [{ "content" => "other def" }] } },
                        ])
      concepts = described_class.collect(@tmpdir)
      expect(concepts.length).to eq(2)
      expect(concepts).to all(be_a(Glossarist::ManagedConcept))
    end

    it "collects managed concept format" do
      concepts = [build_managed_concept("100", "test", "def")]
      create_managed_dataset(@tmpdir, concepts)
      result = described_class.collect(@tmpdir)
      expect(result.length).to eq(1)
      expect(result.first.data.id).to eq("100")
    end

    it "collects v2 flat concept format" do
      concepts = [build_managed_concept("100", "test", "def"),
                  build_managed_concept("200", "other", "other def")]
      create_v2_flat_dataset(@tmpdir, concepts)
      result = described_class.collect(@tmpdir)
      expect(result.length).to eq(2)
      ids = result.map { |mc| mc.data.id }
      expect(ids).to contain_exactly("100", "200")
    end

    it "collects v2 flat concepts with localizations" do
      concepts = [build_managed_concept("100", "test", "def")]
      create_v2_flat_dataset(@tmpdir, concepts)
      result = described_class.collect(@tmpdir)
      mc = result.first
      expect(mc.localization("eng")).to be_a(Glossarist::LocalizedConcept)
      expect(mc.localization("eng").data.terms.first.designation).to eq("test")
    end
  end

  describe ".each_concept" do
    it "streams v2 flat concepts one at a time" do
      concepts = [build_managed_concept("100", "test", "def"),
                  build_managed_concept("200", "other", "other def")]
      create_v2_flat_dataset(@tmpdir, concepts)

      results = []
      described_class.each_concept(@tmpdir) { |mc| results << mc }
      expect(results.length).to eq(2)
      expect(results).to all(be_a(Glossarist::ManagedConcept))
      ids = results.map { |mc| mc.data.id }
      expect(ids).to contain_exactly("100", "200")
    end

    it "returns an enumerator when no block given" do
      concepts = [build_managed_concept("100", "test", "def")]
      create_v2_flat_dataset(@tmpdir, concepts)

      enum = described_class.each_concept(@tmpdir)
      expect(enum).to be_a(Enumerator)
      expect(enum.count).to eq(1)
    end
  end

  describe "format detection priority" do
    it "does not misidentify v1 format as v2 flat" do
      create_v1_dataset(@tmpdir, [
                          { "termid" => "100", "eng" => { "terms" => [{ "type" => "expression", "designation" => "test" }],
                                                          "definition" => [{ "content" => "test def" }] } },
                        ])
      concepts = described_class.collect(@tmpdir)
      expect(concepts.length).to eq(1)
    end

    it "does not misidentify managed format as v2 flat" do
      concepts = [build_managed_concept("100", "test", "def")]
      create_managed_dataset(@tmpdir, concepts)
      result = described_class.collect(@tmpdir)
      expect(result.length).to eq(1)
      expect(result.first.data.id).to eq("100")
    end

    it "does not misidentify managed format as v2 flat even with stray files in concepts/" do
      concepts = [build_managed_concept("100", "test", "def")]
      create_managed_dataset(@tmpdir, concepts)
      # Place a v2-flat-looking file directly in concepts/ alongside managed dirs
      stray_yaml = <<~YAML
        ---
        data:
          identifier: "999"
          localized_concepts:
            eng: stray-lc
        ---
        id: stray-lc
        data:
          language_code: eng
          terms:
            - type: expression
              designation: stray
          definition:
            - content: stray def
      YAML
      File.write(File.join(@tmpdir, "concepts", "stray.yaml"), stray_yaml)
      result = described_class.collect(@tmpdir)
      expect(result.length).to eq(1)
      expect(result.first.data.id).to eq("100")
    end
  end
end
