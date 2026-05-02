# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Glossarist::SchemaMigration do
  describe "CURRENT_SCHEMA_VERSION" do
    it "is '1'" do
      expect(described_class::CURRENT_SCHEMA_VERSION).to eq("1")
    end
  end

  describe "#migrate" do
    it "raises for unsupported migration path" do
      expect do
        described_class.new({}, from_version: "5", to_version: "99").migrate
      end.to raise_error(Glossarist::Error, /Unsupported migration/)
    end

    context "v0 -> v1" do
      context "bare string definition" do
        it "wraps in array" do
          input = { "termid" => "1", "eng" => { "definition" => "some text" } }
          result = described_class.new(input).migrate
          expect(result["eng"]["definition"]).to eq([{ "content" => "some text" }])
        end
      end

      context "array definition" do
        it "is unchanged" do
          defs = [{ "content" => "some text" }]
          input = { "termid" => "1", "eng" => { "definition" => defs } }
          result = described_class.new(input).migrate
          expect(result["eng"]["definition"]).to eq(defs)
        end
      end

      context "authoritative_source to sources" do
        it "converts singular authoritative_source to sources array" do
          input = {
            "termid" => "1",
            "eng" => {
              "authoritative_source" => { "ref" => "ISO 9000",
                                          "link" => "https://example.com" },
            },
          }
          result = described_class.new(input).migrate

          expect(result["eng"]).not_to have_key("authoritative_source")
          expect(result["eng"]["sources"]).to eq([
                                                   {
                                                     "type" => "authoritative",
                                                     "origin" => { "ref" => "ISO 9000",
                                                                   "link" => "https://example.com" },
                                                   },
                                                 ])
        end

        it "does not overwrite existing sources" do
          sources = [{ "type" => "lineage",
                       "origin" => { "ref" => "existing" } }]
          input = {
            "termid" => "1",
            "eng" => {
              "authoritative_source" => { "ref" => "ISO 9000" },
              "sources" => sources,
            },
          }
          result = described_class.new(input).migrate

          expect(result["eng"]["sources"]).to eq(sources)
        end
      end

      context "scalar dates to dates array" do
        it "converts date_accepted to dates array" do
          input = {
            "termid" => "1",
            "eng" => {
              "date_accepted" => "2008-08-01",
            },
          }
          result = described_class.new(input).migrate

          expect(result["eng"]["dates"]).to eq([
                                                 { "type" => "accepted",
                                                   "date" => "2008-08-01" },
                                               ])
        end

        it "preserves existing dates array" do
          dates = [{ "type" => "accepted", "date" => "2008-08-01" }]
          input = {
            "termid" => "1",
            "eng" => { "dates" => dates },
          }
          result = described_class.new(input).migrate

          expect(result["eng"]["dates"]).to eq(dates)
        end
      end

      context "entry status normalization" do
        it 'maps "Standard" to "valid"' do
          input = { "termid" => "1", "eng" => { "entry_status" => "Standard" } }
          result = described_class.new(input).migrate
          expect(result["eng"]["entry_status"]).to eq("valid")
        end

        it 'maps "Confirmed" to "valid"' do
          input = { "termid" => "1",
                    "eng" => { "entry_status" => "Confirmed" } }
          result = described_class.new(input).migrate
          expect(result["eng"]["entry_status"]).to eq("valid")
        end

        it 'maps "Proposed" to "draft"' do
          input = { "termid" => "1", "eng" => { "entry_status" => "Proposed" } }
          result = described_class.new(input).migrate
          expect(result["eng"]["entry_status"]).to eq("draft")
        end

        it "passes through unknown values" do
          input = { "termid" => "1",
                    "eng" => { "entry_status" => "superseded" } }
          result = described_class.new(input).migrate
          expect(result["eng"]["entry_status"]).to eq("superseded")
        end
      end

      context "abbrev to type: abbreviation" do
        it "converts abbrev: true to type: abbreviation" do
          input = {
            "termid" => "1",
            "eng" => {
              "terms" => [{ "designation" => "GIS", "abbrev" => true }],
            },
          }
          result = described_class.new(input).migrate

          term = result["eng"]["terms"][0]
          expect(term["type"]).to eq("abbreviation")
          expect(term).not_to have_key("abbrev")
        end
      end

      context "_revisions stripping" do
        it "removes _revisions from top level" do
          input = { "termid" => "1", "_revisions" => [{ "date" => "2020" }] }
          result = described_class.new(input).migrate
          expect(result).not_to have_key("_revisions")
        end

        it "removes _revisions from language blocks" do
          input = {
            "termid" => "1",
            "eng" => { "definition" => "x",
                       "_revisions" => [{ "date" => "2020" }] },
          }
          result = described_class.new(input).migrate
          expect(result["eng"]).not_to have_key("_revisions")
        end
      end

      context "termid string casting" do
        it "casts integer termid to string" do
          input = { "termid" => 123, "eng" => {} }
          result = described_class.new(input).migrate
          expect(result["termid"]).to eq("123")
        end
      end

      context "inline reference extraction" do
        it "extracts IEV cross-references" do
          input = {
            "termid" => "1",
            "eng" => {
              "definition" => "see {{equality, IEV:102-01-01}} for details",
            },
          }
          result = described_class.new(input).migrate

          expect(result["eng"]["references"]).to include({
            "term" => "equality",
            "concept_id" => "102-01-01",
            "source" => "urn:iec:std:iec:60050",
            "ref_type" => "urn",
          })
        end

        it "extracts URN cross-references" do
          input = {
            "termid" => "1",
            "eng" => {
              "definition" => [{ "content" => "see {urn:iso:std:iso:14812:3.5.1.2,term}" }],
            },
          }
          result = described_class.new(input).migrate

          expect(result["eng"]["references"]).to include({
            "term" => "term",
            "concept_id" => "3.5.1.2",
            "source" => "urn:iso:std:iso:14812",
            "ref_type" => "urn",
          })
        end

        it "deduplicates references" do
          input = {
            "termid" => "1",
            "eng" => {
              "definition" => "see {{a, IEV:1}} and {{b, IEV:1}}",
            },
          }
          result = described_class.new(input).migrate

          iev_refs = result["eng"]["references"].select do |r|
            r["source"] == "urn:iec:std:iec:60050"
          end
          expect(iev_refs.length).to eq(1)
        end
      end

      context "multiple language blocks" do
        it "harmonizes each language independently" do
          input = {
            "termid" => "1",
            "eng" => {
              "definition" => "English def",
              "entry_status" => "Standard",
            },
            "deu" => {
              "definition" => "German def",
              "entry_status" => "Standard",
            },
          }
          result = described_class.new(input).migrate

          expect(result["eng"]["definition"]).to eq([{ "content" => "English def" }])
          expect(result["eng"]["entry_status"]).to eq("valid")
          expect(result["deu"]["definition"]).to eq([{ "content" => "German def" }])
          expect(result["deu"]["entry_status"]).to eq("valid")
        end
      end

      context "combined transformations" do
        it "applies all v0->v1 migrations together" do
          input = {
            "termid" => 42,
            "_revisions" => [{ "date" => "2020" }],
            "eng" => {
              "terms" => [{ "designation" => "FOO", "abbrev" => true }],
              "definition" => "a term, see {{bar, IEV:102-01-01}}",
              "entry_status" => "Standard",
              "date_accepted" => "2010-01-01",
              "authoritative_source" => { "ref" => "ISO 9000" },
              "_revisions" => [{ "date" => "2020" }],
            },
          }
          ref_maps = { ref_prefix_map: { "IEV" => "iev" } }
          result = described_class.new(input, ref_maps: ref_maps).migrate

          # termid stringified
          expect(result["termid"]).to eq("42")
          # _revisions stripped
          expect(result).not_to have_key("_revisions")
          expect(result["eng"]).not_to have_key("_revisions")
          # definition wrapped
          expect(result["eng"]["definition"]).to eq([{ "content" => "a term, see {{bar, IEV:102-01-01}}" }])
          # entry_status normalized
          expect(result["eng"]["entry_status"]).to eq("valid")
          # dates migrated
          expect(result["eng"]["dates"]).to eq([{ "type" => "accepted",
                                                  "date" => "2010-01-01" }])
          # authoritative_source -> sources
          expect(result["eng"]["sources"]).to eq([{ "type" => "authoritative",
                                                    "origin" => { "ref" => "ISO 9000" } }])
          # abbrev -> type
          expect(result["eng"]["terms"][0]["type"]).to eq("abbreviation")
          expect(result["eng"]["terms"][0]).not_to have_key("abbrev")
          # inline refs extracted
          expect(result["eng"]["references"].length).to eq(1)
        end
      end
    end
  end

  describe ".upgrade_directory" do
    before do
      @tmpdir = Dir.mktmpdir
    end

    after do
      FileUtils.rm_rf(@tmpdir)
    end

    def create_source_dataset(concepts)
      source_dir = File.join(@tmpdir, "source")
      concepts_dir = File.join(source_dir, "concepts")
      FileUtils.mkdir_p(concepts_dir)

      concepts.each do |hash|
        termid = hash["termid"]
        File.write(File.join(concepts_dir, "#{termid}.yaml"), YAML.dump(hash))
      end

      source_dir
    end

    it "migrates concepts to directory output" do
      source = create_source_dataset([
        { "termid" => "1", "eng" => { "definition" => "bare text" } },
        { "termid" => "2", "eng" => { "definition" => "another" } },
      ])
      output = File.join(@tmpdir, "output")

      result = described_class.upgrade_directory(source, output: output)
      expect(result[:count]).to eq(2)
      expect(result[:source_version]).to eq("0")
      expect(result[:target_version]).to eq("1")
      expect(File.exist?(File.join(output, "concepts", "1.yaml"))).to be true
      expect(File.exist?(File.join(output, "concepts", "2.yaml"))).to be true
    end

    it "migrates concepts to .gcr output" do
      source = create_source_dataset([
        { "termid" => "1", "eng" => { "definition" => "test" } },
      ])
      output = File.join(@tmpdir, "output.gcr")

      result = described_class.upgrade_directory(source, output: output)
      expect(result[:count]).to eq(1)
      expect(File.exist?(output)).to be true
    end

    it "preserves register.yaml with updated schema_version" do
      source = create_source_dataset([
        { "termid" => "1", "eng" => { "definition" => "test" } },
      ])
      File.write(File.join(source, "register.yaml"), YAML.dump({
        "name" => "Test",
        "schema_version" => "0",
      }))
      output = File.join(@tmpdir, "output")

      described_class.upgrade_directory(source, output: output)
      register = YAML.safe_load_file(File.join(output, "register.yaml"))
      expect(register["schema_version"]).to eq("1")
    end

    it "raises ArgumentError for non-directory source" do
      expect do
        described_class.upgrade_directory("/nonexistent", output: "/tmp/out")
      end.to raise_error(ArgumentError, /not a directory/)
    end

    it "raises ArgumentError when no concept files found" do
      empty_dir = File.join(@tmpdir, "empty")
      FileUtils.mkdir_p(empty_dir)

      expect do
        described_class.upgrade_directory(empty_dir, output: "/tmp/out")
      end.to raise_error(ArgumentError, /No concept YAML files found/)
    end

    it "returns result hash with all keys" do
      source = create_source_dataset([
        { "termid" => "1", "eng" => { "definition" => "test" } },
      ])
      output = File.join(@tmpdir, "output")

      result = described_class.upgrade_directory(source, output: output)
      expect(result).to include(:concepts, :register_data, :source_version,
                                :target_version, :output, :count)
    end
  end
end
