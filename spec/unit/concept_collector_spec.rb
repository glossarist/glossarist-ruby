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
    mc = Glossarist::ManagedConcept.new(data: { id: termid })
    l10n = Glossarist::LocalizedConcept.of_yaml({
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
  end
end
