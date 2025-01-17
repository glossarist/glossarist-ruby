# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::LocalizedConcept do
  subject { described_class.from_yaml({ "data" => attrs }.to_yaml) }

  let(:attrs) { { language_code: "eng" } }

  it "accepts strings as ids" do
    expect { subject.id = "456" }
      .to change { subject.id }.to("456")
  end

  # it "raises error if id is nil" do
  #   expect { subject.id = nil }
  #     .to raise_error(Glossarist::Error, "Expect id to be a String or Integer, Got NilClass ()")
  # end

  # it "raises error if id is not a `String` or `Integer`" do
  #   expect { subject.id = false }
  #     .to raise_error(Glossarist::Error, "Expect id to be a String or Integer, Got FalseClass (false)")
  # end

  it "accepts strings as language codes" do
    expect { subject.language_code = "deu" }
      .to change { subject.language_code }.to("deu")
  end

  it "raises error if language_code is not 3 characters long" do
    subject.language_code = "urdu"
    expect { subject.validate! }
      .to raise_error(Lutaml::Model::ValidationError)
  end

  it "accepts strings as definitions" do
    definition = Glossarist::DetailedDefinition.new({ content: "this is very important" })

    expect { subject.definition = [ definition ] }
      .to change { subject.definition.count }.from(0).to(1)
  end

  it "accepts strings as entry statuses" do
    expect { subject.entry_status = "valid" }
      .to change { subject.entry_status }.to("valid")
  end

  it "accepts strings as classifications" do
    expect { subject.classification = "admitted" }
      .to change { subject.classification }.to("admitted")
  end

  it "accepts strings as review dates" do
    expect { subject.review_date = "2020-01-01" }
      .to change { subject.review_date }.to(Date.parse("2020-01-01"))
  end

    it "is a collection of designations" do
      expect { subject.designations << expression }
        .to change { subject.designations.count }.from(0).to(1)
    end

    it "is aliased as 'terms'" do
      expect { subject.designations << expression }
        .to change { subject.terms.count }.from(0).to(1)
    end
  end

  describe "#notes" do
    it "adds a note of type DetailedDefinition", skip: "will work when custom collection classes are implemented in lutaml-model" do
      expect { subject.notes << "str" }
        .to change { subject.notes.count }.from(0).to(1)
        .and change { subject.notes.first.class }.from(NilClass).to(Glossarist::DetailedDefinition)
    end
  end

  describe "#examples" do
    it "adds an example of type DetailedDefinition", skip: "will work when custom collection classes are implemented in lutaml-model" do
      expect { subject.examples << "example" }
        .to change { subject.examples.count }.from(0).to(1)
        .and change { subject.examples.first.class }.from(NilClass).to(Glossarist::DetailedDefinition)
    end
  end

  describe "#sources" do
    let(:item) { { "text" => "source" } }

    it "is an array", skip: "will work when custom collection classes are implemented in lutaml-model" do
      expect { subject.sources << item }
        .to change { subject.sources.count }.from(0).to(1)
        .and change { subject.sources.first.class }.from(NilClass).to(Glossarist::ConceptSource)
    end
  end

  describe "#to_yaml" do
    it "dumps localized concept definition to a hash" do
      term1 = { "type" => "expression", "designation" => "term1" }
      term2 = { "type" => "expression", "designation" => "term2" }
      source = { "type" => "authoritative", "status" => "modified" }
      attrs.replace({
        "id" => "123",
        "language_code" => "eng",
        "terms" => [term1, term2],
        "examples" => [{ "content" => "ex. one" }],
        "notes" => [{ "content" => "note one" }],
        "sources" => [source],
      })

      retval = YAML.load(subject.to_yaml)["data"]

      expect(retval).to be_kind_of(Hash)
      expect(retval["language_code"]).to eq("eng")
      expect(retval["id"]).to eq("123")
      expect(retval["terms"]).to eq([term1, term2])
      expect(retval["examples"]).to eq([{ "content" => "ex. one"}])
      expect(retval["notes"]).to eq([{ "content" => "note one"}])
      expect(retval["sources"]).to eq([source])
    end
  end

  describe "::from_yaml" do
    it "loads localized concept definition from a yaml" do
      source = {
        "origin" => {
          "source" => "wikipedia",
          "id" => "123",
          "version" => "71",
        },
        "type" => "authoritative",
      }

      src = {
        "data" => {
          "id" => "123-45",
          "language_code" => "eng",
          "terms" => [
            {
              "designation" => "Example Designation",
              "type" => "expression",
              "normative_status" => "preferred",
            },
          ],
          "definition" => [{ content: "Example Definition" }],
          "sources" => [source],
        },
        "id" => "some-random-uuid",
      }.to_yaml

      retval = described_class.from_yaml(src)

      expect(retval).to be_kind_of(Glossarist::LocalizedConcept)
      expect(retval.id).to eq("some-random-uuid")
      expect(retval.data.id).to eq("123-45")
      expect(retval.data.definition.size).to eq(1)
      expect(retval.data.definition.first.content).to eq("Example Definition")
      expect(retval.terms.size).to eq(1)
      expect(retval.terms.first.class).to eq(Glossarist::Designation::Expression)
      expect(retval.terms.first.normative_status).to eq("preferred")
      expect(retval.terms.first.designation).to eq("Example Designation")
      expect(retval.sources.map(&:to_yaml_hash)).to eq([{"origin"=>{"ref"=>{"id"=>"123", "source"=>"wikipedia", "version"=>"71"}}, "type"=>"authoritative"}])
    end

    it "should work iev-data for grammar_info" do
      src = {
        "data" => {
          "id" => "103-01-12",
          "language_code" => "eng",
          "terms" => [
            {
              "designation" => "Intervall",
              "type" => "expression",
              "normative_status" => "preferred",
              "part_of_speech" => "adj",
              "gender" => "n",
              "plurality" => "singular",
            },
          ],
          "definition" => [{ content: "set of real numbers such that, for any pair (stem:[x], stem:[y]) of elements of the set, any real number stem:[z] between stem:[x] and stem:[y] belongs to the set" }],
        },
      }.to_yaml

      localized_concept = Glossarist::LocalizedConcept.from_yaml(src)
      grammar_info = localized_concept.designations.first.grammar_info.first

      expect(grammar_info.n?).to be(true)
      expect(grammar_info.adj?).to be(true)
      expect(grammar_info.singular?).to be(true)
    end
  end
end
