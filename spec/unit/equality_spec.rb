# frozen_string_literal: true

require "spec_helper"

# Verifies lutaml-model's ComparableModel is wired into Glossarist model
# classes via Lutaml::Model::Serializable. Per issue #137: "LutaML Models
# supports direct comparison through ComparableModel, ensure it works here."
#
# Serializable already includes ComparableModel (see lutaml-model 0.8.x),
# so all our model classes inherit ==, eql?, and hash based on attributes.
# These specs lock in the behavior so a future lutaml-model change doesn't
# silently break diff/dedup use cases.
RSpec.describe "Glossarist model equality (issue #137, ComparableModel)" do
  def make_localized_concept(term: "alpha", lang: "eng")
    Glossarist::LocalizedConcept.of_yaml({
      "data" => {
        "language_code" => lang,
        "terms" => [{ "type" => "expression", "designation" => term,
                      "normative_status" => "preferred" }],
        "definition" => [{ "content" => "a definition" }],
        "entry_status" => "valid",
      },
    })
  end

  def make_managed_concept(id: "1.1", l10n: nil)
    mc = Glossarist::ManagedConcept.new(data: { "id" => id })
    mc.add_localization(l10n || make_localized_concept) if l10n
    mc
  end

  describe Glossarist::ManagedConcept do
    it "is equal to another instance with identical attributes" do
      a = make_managed_concept(id: "1.1")
      b = make_managed_concept(id: "1.1")
      expect(a).to eq(b)
    end

    it "is unequal when an attribute differs" do
      a = make_managed_concept(id: "1.1")
      b = make_managed_concept(id: "1.2")
      expect(a).not_to eq(b)
    end

    it "round-trips equality through YAML" do
      a = make_managed_concept(id: "1.1")
      b = Glossarist::ManagedConcept.from_yaml(a.to_yaml)
      expect(a).to eq(b)
    end

    it "eql? agrees with ==" do
      a = make_managed_concept
      b = make_managed_concept
      expect(a.eql?(b)).to be true
      expect(a == b).to be true
    end
  end

  describe Glossarist::LocalizedConcept do
    it "is equal across identical constructions" do
      expect(make_localized_concept(term: "x")).to eq(make_localized_concept(term: "x"))
    end

    it "differs when the term differs" do
      a = make_localized_concept(term: "alpha")
      b = make_localized_concept(term: "beta")
      expect(a).not_to eq(b)
    end

    it "differs when the language differs" do
      a = make_localized_concept(lang: "eng")
      b = make_localized_concept(lang: "fra")
      expect(a).not_to eq(b)
    end
  end

  describe Glossarist::ConceptReference do
    it "is equal for identical concept_id + source" do
      a = Glossarist::ConceptReference.new(concept_id: "1", source: "urn:iso:1")
      b = Glossarist::ConceptReference.new(concept_id: "1", source: "urn:iso:1")
      expect(a).to eq(b)
    end

    it "differs when concept_id differs" do
      a = Glossarist::ConceptReference.new(concept_id: "1")
      b = Glossarist::ConceptReference.new(concept_id: "2")
      expect(a).not_to eq(b)
    end
  end

  describe Glossarist::Designation::Base do
    it "is equal for identical attributes" do
      a = Glossarist::Designation::Expression.new(designation: "alpha",
                                                  normative_status: "preferred")
      b = Glossarist::Designation::Expression.new(designation: "alpha",
                                                  normative_status: "preferred")
      expect(a).to eq(b)
    end

    it "differs when designation text differs" do
      a = Glossarist::Designation::Expression.new(designation: "alpha")
      b = Glossarist::Designation::Expression.new(designation: "beta")
      expect(a).not_to eq(b)
    end
  end

  describe Glossarist::DetailedDefinition do
    it "is equal for identical content" do
      a = Glossarist::DetailedDefinition.new(content: "Same content")
      b = Glossarist::DetailedDefinition.new(content: "Same content")
      expect(a).to eq(b)
    end

    it "differs when content differs" do
      a = Glossarist::DetailedDefinition.new(content: "a")
      b = Glossarist::DetailedDefinition.new(content: "b")
      expect(a).not_to eq(b)
    end
  end

  describe Glossarist::ConceptSource do
    it "is equal for identical type" do
      a = Glossarist::ConceptSource.new(type: "authoritative")
      b = Glossarist::ConceptSource.new(type: "authoritative")
      expect(a).to eq(b)
    end

    it "differs when type differs" do
      a = Glossarist::ConceptSource.new(type: "authoritative")
      b = Glossarist::ConceptSource.new(type: "lineage")
      expect(a).not_to eq(b)
    end
  end

  describe "Hash/Set usage" do
    it "two equal instances dedup in a Set" do
      a = make_managed_concept(id: "1.1")
      b = make_managed_concept(id: "1.1")
      expect(Set.new([a, b]).size).to eq(1)
    end

    it "two unequal instances stay distinct in a Set" do
      a = make_managed_concept(id: "1.1")
      b = make_managed_concept(id: "1.2")
      expect(Set.new([a, b]).size).to eq(2)
    end

    it "two equal instances share a hash key" do
      a = make_managed_concept(id: "1.1")
      b = make_managed_concept(id: "1.1")
      expect(a.hash).to eq(b.hash)
    end
  end
end
