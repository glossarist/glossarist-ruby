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
      .to change { subject.dates&.count || 0 }.from(0).to(1)
  end

  it "accepts definition collection" do
    definition = Glossarist::DetailedDefinition.new(content: "test definition")
    expect { subject.definition = [definition] }
      .to change { subject.definition&.count || 0 }.from(0).to(1)
  end

  it "accepts examples collection" do
    example = Glossarist::DetailedDefinition.new(content: "test example")
    expect { subject.examples = [example] }
      .to change { subject.examples&.count || 0 }.from(0).to(1)
  end

  it "accepts integer for lineage_source_similarity" do
    expect { subject.lineage_source_similarity = 80 }
      .to change { subject.lineage_source_similarity }.to(80)
  end

  it "accepts strings as release" do
    expect { subject.release = "1.0" }
      .to change { subject.release }.to("1.0")
  end

  it "accepts sources collection" do
    source = Glossarist::ConceptSource.new(type: "authoritative")
    expect { subject.sources = [source] }
      .to change { subject.sources&.count || 0 }.from(0).to(1)
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

  describe "#script" do
    it "accepts ISO 15924 script codes" do
      expect { subject.script = "Hans" }
        .to change { subject.script }.to("Hans")
    end

    it "round-trips through YAML" do
      subject.language_code = "zho"
      subject.script = "Hans"
      roundtrip = described_class.from_yaml(subject.to_yaml)
      expect(roundtrip.script).to eq("Hans")
    end
  end

  describe "#system" do
    it "accepts ISO 24229 conversion system codes" do
      expect { subject.system = "Var:jpn-Hrkt:Latn:Hepburn-1886" }
        .to change { subject.system }.to("Var:jpn-Hrkt:Latn:Hepburn-1886")
    end

    it "round-trips through YAML" do
      subject.language_code = "jpn"
      subject.script = "Latn"
      subject.system = "Var:jpn-Hrkt:Latn:Hepburn-1886"
      roundtrip = described_class.from_yaml(subject.to_yaml)
      expect(roundtrip.language_code).to eq("jpn")
      expect(roundtrip.script).to eq("Latn")
      expect(roundtrip.system).to eq("Var:jpn-Hrkt:Latn:Hepburn-1886")
    end
  end

  describe "#domain" do
    it "accepts relative URI references" do
      expect { subject.domain = "section-103-01" }
        .to change { subject.domain }.to("section-103-01")
    end

    it "accepts absolute URI references" do
      uri = "https://www.electropedia.org/iev/iev.nsf/display?openform&ievref=103-01"
      expect { subject.domain = uri }
        .to change { subject.domain }.to(uri)
    end

    it "accepts URN references" do
      urn = "urn:iec:std:iec:60050-103-01"
      expect { subject.domain = urn }
        .to change { subject.domain }.to(urn)
    end

    it "round-trips relative URIs through YAML" do
      subject.domain = "section-103-01"
      roundtrip = described_class.from_yaml(subject.to_yaml)
      expect(roundtrip.domain).to eq("section-103-01")
    end

    it "round-trips absolute URIs through YAML" do
      subject.domain = "https://example.org/concepts/103-01"
      roundtrip = described_class.from_yaml(subject.to_yaml)
      expect(roundtrip.domain).to eq("https://example.org/concepts/103-01")
    end

    it "round-trips URNs through YAML" do
      subject.domain = "urn:iec:std:iec:60050-103-01"
      roundtrip = described_class.from_yaml(subject.to_yaml)
      expect(roundtrip.domain).to eq("urn:iec:std:iec:60050-103-01")
    end
  end

  describe "#terms_from_yaml" do
    it "converts yaml to term objects" do
      term_data = [{ "type" => "expression", "designation" => "test term" }]
      subject.terms_from_yaml(subject, term_data)
      expect(subject.terms.first).to be_an_instance_of(Glossarist::Designation::Expression)
    end

    it "preserves field_of_application on expression terms" do
      term_data = [{
        "type" => "expression",
        "designation" => "information",
        "field_of_application" => "in communication theory",
      }]
      subject.terms_from_yaml(subject, term_data)
      expect(subject.terms.first.field_of_application).to eq("in communication theory")
    end

    it "preserves absent flag on terms" do
      term_data = [{
        "type" => "expression",
        "designation" => "test",
        "absent" => true,
      }]
      subject.terms_from_yaml(subject, term_data)
      expect(subject.terms.first.absent).to eq(true)
    end

    it "preserves pronunciation on terms" do
      term_data = [{
        "type" => "expression",
        "designation" => "quality",
        "pronunciation" => [
          { "content" => "ˈkwɒl.ɪ.ti", "language" => "eng", "script" => "Latn",
            "system" => "IPA" },
        ],
      }]
      subject.terms_from_yaml(subject, term_data)
      pron = subject.terms.first.pronunciation.first
      expect(pron.content).to eq("ˈkwɒl.ɪ.ti")
      expect(pron.language).to eq("eng")
      expect(pron.script).to eq("Latn")
      expect(pron.system).to eq("IPA")
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

      roundtrip = described_class.from_yaml(subject.to_yaml)
      expect(roundtrip.id).to eq("test-123")
      expect(roundtrip.language_code).to eq("eng")
      expect(roundtrip.entry_status).to eq("valid")
    end

    it "round-trips all designation metadata" do
      term = Glossarist::Designation::Expression.new(
        designation: "information",
        normative_status: "preferred",
        field_of_application: "in communication theory",
        usage_info: "telecom",
        absent: false,
        pronunciation: [
          Glossarist::Pronunciation.new(
            content: "ˌɪnfərˈmeɪʃən",
            language: "eng",
            script: "Latn",
            system: "IPA",
          ),
        ],
        international: true,
      )
      subject.terms = [term]
      subject.domain = "section-103-01"

      roundtrip = described_class.from_yaml(subject.to_yaml)
      rt_term = roundtrip.terms.first
      expect(rt_term.designation).to eq("information")
      expect(rt_term.field_of_application).to eq("in communication theory")
      expect(rt_term.usage_info).to eq("telecom")
      expect(rt_term.pronunciation.first.content).to eq("ˌɪnfərˈmeɪʃən")
      expect(rt_term.pronunciation.first.language).to eq("eng")
      expect(rt_term.pronunciation.first.script).to eq("Latn")
      expect(rt_term.pronunciation.first.system).to eq("IPA")
      expect(rt_term.international).to eq(true)
      expect(roundtrip.domain).to eq("section-103-01")
    end
  end
end
