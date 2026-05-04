# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ReferenceExtractor do
  subject { described_class.new }

  describe "local (intra-set) references" do
    it "extracts {{geodetic latitude, 200}} (ID with display override)" do
      refs = subject.extract_from_text("See {{geodetic latitude, 200}} for details.")

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.term).to eq("geodetic latitude")
      expect(ref.concept_id).to eq("200")
      expect(ref.source).to be_nil
      expect(ref.ref_type).to eq("local")
      expect(ref).to be_local
    end

    it "extracts {{200}} (ID only, auto-display)" do
      refs = subject.extract_from_text("See {{200}} for details.")

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.term).to eq("200")
      expect(ref.concept_id).to eq("200")
      expect(ref.source).to be_nil
      expect(ref.ref_type).to eq("local")
    end

    it "extracts {{3.1.32}} (dotted numeric ID)" do
      refs = subject.extract_from_text("See {{3.1.32}}.")

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.concept_id).to eq("3.1.32")
      expect(ref.ref_type).to eq("local")
    end
  end

  describe "designation lookup" do
    it "extracts {{geodetic latitude}} (no ID, designation lookup)" do
      refs = subject.extract_from_text("See {{geodetic latitude}} for details.")

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.term).to eq("geodetic latitude")
      expect(ref.concept_id).to be_nil
      expect(ref.source).to be_nil
      expect(ref.ref_type).to eq("designation")
      expect(ref).to be_local
    end
  end

  describe "IEC URN references" do
    it "extracts {{equality, urn:iec:std:iec:60050-102-01-01}}" do
      refs = subject.extract_from_text("See {{equality, urn:iec:std:iec:60050-102-01-01}}.")

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.term).to eq("equality")
      expect(ref.concept_id).to eq("102-01-01")
      expect(ref.source).to eq("urn:iec:std:iec:60050")
      expect(ref.ref_type).to eq("urn")
      expect(ref).to be_external
    end

    it "extracts {{urn:iec:std:iec:60050-102-01-01}} (URN only, no display)" do
      refs = subject.extract_from_text("See {{urn:iec:std:iec:60050-102-01-01}}.")

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.term).to eq("")
      expect(ref.concept_id).to eq("102-01-01")
      expect(ref.source).to eq("urn:iec:std:iec:60050")
      expect(ref.ref_type).to eq("urn")
    end

    it "extracts concept_id from dated IEC URN" do
      refs = subject.extract_from_text("{{term, urn:iec:std:iec:60050-121-10-34:2016-11}}")

      expect(refs.first.concept_id).to eq("121-10-34")
      expect(refs.first.source).to eq("urn:iec:std:iec:60050")
    end

    it "extracts concept_id from fragment-style IEC URN" do
      refs = subject.extract_from_text("{{term, urn:iec:std:iec:60050-121:2010-10::#con-121-10-23}}")

      expect(refs.first.concept_id).to eq("121-10-23")
      expect(refs.first.source).to eq("urn:iec:std:iec:60050")
    end
  end

  describe "ISO URN references" do
    it "extracts {{latitude, urn:iso:std:iso:19111:ed-3:v1:en:term:3.1.32}}" do
      text = "{{latitude, urn:iso:std:iso:19111:ed-3:v1:en:term:3.1.32}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.term).to eq("latitude")
      expect(ref.concept_id).to eq("3.1.32")
      expect(ref.source).to eq("urn:iso:std:iso:19111")
      expect(ref.ref_type).to eq("urn")
    end

    it "stores URN prefix as source, not derived shortname" do
      text = "{{lat, urn:iso:std:iso:19111:ed-3:v1:en:term:3.1.32}}"
      refs = subject.extract_from_text(text)

      expect(refs.first.source).to eq("urn:iso:std:iso:19111")
    end
  end

  describe "generic URN references" do
    it "stores the full URN as source when scheme is unknown" do
      text = "{{term, urn:custom:std:123}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(1)
      ref = refs.first
      expect(ref.source).to eq("urn:custom:std:123")
      expect(ref.concept_id).to be_nil
      expect(ref.ref_type).to eq("urn")
    end
  end

  describe "mixed references" do
    it "extracts local and URN references together" do
      text = "{{local ref, 200}} and {{equality, urn:iec:std:iec:60050-102-01-01}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(2)
      local_ref = refs.find { |r| r.ref_type == "local" }
      urn_ref = refs.find { |r| r.ref_type == "urn" }

      expect(local_ref.concept_id).to eq("200")
      expect(local_ref.source).to be_nil
      expect(urn_ref.concept_id).to eq("102-01-01")
      expect(urn_ref.source).to eq("urn:iec:std:iec:60050")
    end
  end

  describe "deduplication" do
    it "deduplicates by source + concept_id" do
      text = "{{a, 200}} and {{b, 200}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(1)
      expect(refs.first.term).to eq("a")
    end

    it "deduplicates URN refs by source + concept_id" do
      text = "{{a, urn:iec:std:iec:60050-102-01-01}} and {{b, urn:iec:std:iec:60050-102-01-01}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(1)
    end

    it "does not deduplicate designation refs with different terms" do
      text = "{{geodetic latitude}} and {{latitude}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(2)
      expect(refs.map(&:term)).to contain_exactly("geodetic latitude",
                                                  "latitude")
    end

    it "deduplicates identical designation refs" do
      text = "{{latitude}} and {{latitude}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(1)
    end
  end

  describe "multiple references in one text" do
    it "extracts all references" do
      text = "{{lat, 200}} and {{lon, 201}} and {{eq, urn:iec:std:iec:60050-102-01-01}}"
      refs = subject.extract_from_text(text)

      expect(refs.size).to eq(3)
    end
  end

  describe "edge cases" do
    it "returns empty array for nil text" do
      expect(subject.extract_from_text(nil)).to eq([])
    end

    it "returns empty array for empty text" do
      expect(subject.extract_from_text("")).to eq([])
    end

    it "returns empty array for text with no references" do
      expect(subject.extract_from_text("plain text without references")).to eq([])
    end
  end

  describe "#extract_from_localized" do
    it "extracts from definition, notes, and examples" do
      lc_hash = {
        "definition" => [{ "content" => "See {{term1, 100}}" }],
        "notes" => [{ "content" => "Note about {{term2, urn:iec:std:iec:60050-102-01-01}}" }],
        "examples" => [{ "content" => "Example: {{term3, 300}}" }],
      }

      refs = subject.extract_from_localized(lc_hash)

      expect(refs.size).to eq(3)
      expect(refs.map(&:concept_id)).to contain_exactly("100", "102-01-01",
                                                        "300")
    end
  end

  describe "#extract_from_concept_hash" do
    it "extracts from all language blocks" do
      concept_hash = {
        "eng" => {
          "definition" => [{ "content" => "See {{term1, 100}}" }],
          "notes" => [],
          "examples" => [],
        },
        "fra" => {
          "definition" => [{ "content" => "Voir {{term2, 200}}" }],
          "notes" => [],
          "examples" => [],
        },
      }

      refs = subject.extract_from_concept_hash(concept_hash)

      expect(refs.size).to eq(2)
      expect(refs.map(&:concept_id)).to contain_exactly("100", "200")
    end
  end

  describe "custom identifier resolver registration" do
    it "allows registering new identifier resolvers" do
      described_class.register_identifier_resolver("doi:") do |_ext, identifier, display|
        Glossarist::ConceptReference.new(
          term: display || "",
          concept_id: identifier.sub("doi:", ""),
          source: identifier,
          ref_type: "urn",
        )
      end

      extractor = described_class.new
      refs = extractor.extract_from_text("See {{paper, doi:10.1234/5678}}")

      expect(refs.size).to eq(1)
      expect(refs.first.concept_id).to eq("10.1234/5678")
      expect(refs.first.source).to eq("doi:10.1234/5678")
    ensure
      described_class.identifier_resolvers.pop
    end
  end
end
