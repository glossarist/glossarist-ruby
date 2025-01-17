RSpec.describe Glossarist::ConceptData do
  subject { described_class.from_yaml({ "data" => attrs }.to_yaml) }

  let(:attrs) { {} }

  it "accepts strings as ids" do
    expect { subject.id = "123" }
      .to change { subject.id }.to("123")
  end

  it "accepts dates collection" do
    date = Glossarist::ConceptDate.new(type: "accepted")
    expect { subject.dates = [date] }
      .to change { subject.dates.count }.from(0).to(1)
  end

  it "accepts definition collection" do
    definition = Glossarist::DetailedDefinition.new(content: "test definition")
    expect { subject.definition = [definition] }
      .to change { subject.definition.count }.from(0).to(1)
  end

  it "accepts examples collection" do
    example = Glossarist::DetailedDefinition.new(content: "test example")
    expect { subject.examples = [example] }
      .to change { subject.examples.count }.from(0).to(1)
  end

  it "accepts integer for lineage_source_similarity" do
    expect { subject.lineage_source_similarity = 80 }
      .to change { subject.lineage_source_similarity }.to(80)
  end

  it "accepts string as release" do
    expect { subject.release = "1.0" }
      .to change { subject.release }.to("1.0")
  end

  it "accepts sources collection" do
    source = Glossarist::ConceptSource.new(type: "authoritative")
    expect { subject.sources = [source] }
      .to change { subject.sources.count }.from(0).to(1)
  end

  it "accepts strings as review dates" do
    expect { subject.review_date = "2020-01-01" }
      .to change { subject.review_date }.to(Date.parse("2020-01-01"))
  end

  it "accepts strings as review decision dates" do
    expect { subject.review_decision_date = "2020-01-01" }
      .to change { subject.review_decision_date }.to(Date.parse("2020-01-01"))
  end

  it "accepts strings as review decision events" do
    expect { subject.review_decision_event = "published" }
      .to change { subject.review_decision_event }.to("published")
  end

  describe "#terms_from_yaml" do
    it "converts yaml to term objects" do
      term_data = [{ "type" => "expression", "designation" => "test term" }]
      subject.terms_from_yaml(subject, term_data)
      expect(subject.terms.first).to be_an_instance_of(Glossarist::Designation::Expression)
    end
  end

  describe "#date_accepted" do
    it "returns the accepted date" do
      accepted_date = Glossarist::ConceptDate.new(type: "accepted")
      other_date = Glossarist::ConceptDate.new(type: "updated")
      subject.dates = [other_date, accepted_date]

      expect(subject.date_accepted).to eq(accepted_date)
    end
  end

  describe "#authoritative_source" do
    it "returns authoritative sources" do
      auth_source = Glossarist::ConceptSource.new(type: "authoritative")
      other_source = Glossarist::ConceptSource.new(type: "lineage")
      subject.sources = [other_source, auth_source]

      expect(subject.authoritative_source).to eq([auth_source])
    end
  end

  describe "#to_yaml" do
    it "serializes to valid yaml format" do
      subject.id = "test-123"
      subject.language_code = "eng"
      subject.entry_status = "valid"

      yaml = YAML.safe_load(subject.to_yaml)
      expect(yaml["id"]).to eq("test-123")
      expect(yaml["language_code"]).to eq("eng")
      expect(yaml["entry_status"]).to eq("valid")
    end
  end
end
