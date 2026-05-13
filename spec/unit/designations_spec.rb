# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Pronunciation do
  it "stores content with ISO 639 language code" do
    p = described_class.new(content: "toːkjoː", language: "jpn",
                            script: "Latn", system: "IPA")
    expect(p.content).to eq("toːkjoː")
    expect(p.language).to eq("jpn")
    expect(p.script).to eq("Latn")
    expect(p.system).to eq("IPA")
  end

  it "round-trips through YAML" do
    src = {
      "content" => "toːkjoː",
      "language" => "jpn",
      "script" => "Latn",
      "system" => "IPA",
    }.to_yaml

    p = described_class.from_yaml(src)
    expect(p.content).to eq("toːkjoː")
    expect(p.language).to eq("jpn")
    expect(p.script).to eq("Latn")
    expect(p.system).to eq("IPA")

    roundtrip = described_class.from_yaml(p.to_yaml)
    expect(roundtrip.content).to eq("toːkjoː")
    expect(roundtrip.language).to eq("jpn")
    expect(roundtrip.script).to eq("Latn")
    expect(roundtrip.system).to eq("IPA")
  end

  it "accepts ISO 24229 conversion system codes" do
    p = described_class.new(
      content: "Tōkyō",
      language: "jpn",
      script: "Latn",
      system: "Var:jpn-Hrkt:Latn:Hepburn-1886",
    )
    expect(p.system).to eq("Var:jpn-Hrkt:Latn:Hepburn-1886")
  end

  it "accepts country code for dialect variants" do
    p = described_class.new(
      content: "ˈæp.əl",
      language: "eng",
      script: "Latn",
      country: "US",
      system: "IPA",
    )
    expect(p.country).to eq("US")
  end
end

RSpec.describe Glossarist::Designation::Base do
  describe "base metadata attributes" do
    describe "#absent" do
      it "accepts boolean values" do
        expr = described_class.new(designation: "test")
        expect { expr.absent = true }
          .to change { expr.absent }.to(true)
      end

      it "round-trips through YAML" do
        expr = described_class.from_yaml({
          "type" => "expression",
          "designation" => "test",
          "absent" => true,
        }.to_yaml)
        expect(expr.absent).to eq(true)

        roundtrip = described_class.from_yaml(expr.to_yaml)
        expect(roundtrip.absent).to eq(true)
      end
    end

    describe "#pronunciation" do
      it "accepts a collection of Pronunciation objects" do
        expr = described_class.new(designation: "test")
        pron = Glossarist::Pronunciation.new(
          content: "toːkjoː", language: "jpn", script: "Latn", system: "IPA",
        )
        expect { expr.pronunciation = [pron] }
          .to change { expr.pronunciation&.count || 0 }.from(0).to(1)
      end

      it "round-trips multiple pronunciations through YAML" do
        src = {
          "type" => "expression",
          "designation" => "東京",
          "pronunciation" => [
            { "content" => "toːkjoː", "language" => "jpn", "script" => "Latn",
              "system" => "IPA" },
            { "content" => "Tōkyō", "language" => "jpn", "script" => "Latn",
              "system" => "Var:jpn-Hrkt:Latn:Hepburn-1886" },
          ],
        }.to_yaml

        expr = described_class.from_yaml(src)
        expect(expr.pronunciation.count).to eq(2)
        expect(expr.pronunciation[0].content).to eq("toːkjoː")
        expect(expr.pronunciation[0].language).to eq("jpn")
        expect(expr.pronunciation[0].script).to eq("Latn")
        expect(expr.pronunciation[0].system).to eq("IPA")
        expect(expr.pronunciation[1].content).to eq("Tōkyō")
        expect(expr.pronunciation[1].system).to eq("Var:jpn-Hrkt:Latn:Hepburn-1886")

        roundtrip = described_class.from_yaml(expr.to_yaml)
        expect(roundtrip.pronunciation.count).to eq(2)
        expect(roundtrip.pronunciation[0].content).to eq("toːkjoː")
        expect(roundtrip.pronunciation[1].content).to eq("Tōkyō")
      end

      it "handles pronunciation with country code for dialect variants" do
        src = {
          "type" => "expression",
          "designation" => "water",
          "pronunciation" => [
            { "content" => "ˈwɑːtər", "language" => "eng", "script" => "Latn",
              "country" => "US", "system" => "IPA" },
            { "content" => "ˈwɔːtə", "language" => "eng", "script" => "Latn",
              "country" => "GB", "system" => "IPA" },
          ],
        }.to_yaml

        expr = described_class.from_yaml(src)
        expect(expr.pronunciation[0].country).to eq("US")
        expect(expr.pronunciation[1].country).to eq("GB")
      end
    end

    describe "#international" do
      it "accepts boolean values on Base" do
        expr = described_class.new(designation: "test")
        expect { expr.international = true }
          .to change { expr.international }.to(true)
      end

      it "round-trips through YAML on Expression" do
        expr = Glossarist::Designation::Expression.from_yaml({
          "type" => "expression",
          "designation" => "ISO",
          "international" => true,
        }.to_yaml)
        expect(expr.international).to eq(true)

        roundtrip = Glossarist::Designation::Expression.from_yaml(expr.to_yaml)
        expect(roundtrip.international).to eq(true)
      end

      it "is available on Symbol via inheritance" do
        sym = Glossarist::Designation::Symbol.from_yaml({
          "type" => "symbol",
          "designation" => "Ω",
          "international" => true,
        }.to_yaml)
        expect(sym.international).to eq(true)
      end

      it "is available on Abbreviation via inheritance" do
        abbr = Glossarist::Designation::Abbreviation.from_yaml({
          "type" => "abbreviation",
          "designation" => "NASA",
          "international" => true,
          "acronym" => true,
        }.to_yaml)
        expect(abbr.international).to eq(true)
      end

      it "is available on LetterSymbol via inheritance" do
        ls = Glossarist::Designation::LetterSymbol.from_yaml({
          "type" => "letter_symbol",
          "designation" => "A",
          "international" => true,
          "text" => "A",
        }.to_yaml)
        expect(ls.international).to eq(true)
      end

      it "is available on GraphicalSymbol via inheritance" do
        gs = Glossarist::Designation::GraphicalSymbol.from_yaml({
          "type" => "graphical_symbol",
          "designation" => "♔",
          "international" => true,
          "text" => "king",
          "image" => "♔",
        }.to_yaml)
        expect(gs.international).to eq(true)
      end
    end
  end

  describe "#language and #script" do
    it "accepts ISO 639 language code on designations" do
      expr = Glossarist::Designation::Expression.from_yaml({
        "type" => "expression",
        "designation" => "東京",
        "language" => "jpn",
        "script" => "Hani",
      }.to_yaml)
      expect(expr.language).to eq("jpn")
      expect(expr.script).to eq("Hani")
    end

    it "allows different scripts for the same language" do
      kanji = Glossarist::Designation::Expression.from_yaml({
        "type" => "expression",
        "designation" => "東京",
        "language" => "jpn",
        "script" => "Hani",
      }.to_yaml)
      romaji = Glossarist::Designation::Expression.from_yaml({
        "type" => "expression",
        "designation" => "Tōkyō",
        "language" => "jpn",
        "script" => "Latn",
      }.to_yaml)
      expect(kanji.script).to eq("Hani")
      expect(romaji.script).to eq("Latn")
      expect(kanji.language).to eq(romaji.language)
    end

    it "round-trips language and script through YAML" do
      src = {
        "type" => "expression",
        "designation" => "東京",
        "language" => "jpn",
        "script" => "Hani",
      }.to_yaml

      expr = Glossarist::Designation::Expression.from_yaml(src)
      roundtrip = Glossarist::Designation::Expression.from_yaml(expr.to_yaml)
      expect(roundtrip.language).to eq("jpn")
      expect(roundtrip.script).to eq("Hani")
    end

    it "round-trips system (ISO 24229 conversion system code) through YAML" do
      src = {
        "type" => "expression",
        "designation" => "Tōkyō",
        "language" => "jpn",
        "script" => "Latn",
        "system" => "Var:jpn-Hrkt:Latn:Hepburn-1886",
      }.to_yaml

      expr = Glossarist::Designation::Expression.from_yaml(src)
      expect(expr.system).to eq("Var:jpn-Hrkt:Latn:Hepburn-1886")

      roundtrip = Glossarist::Designation::Expression.from_yaml(expr.to_yaml)
      expect(roundtrip.system).to eq("Var:jpn-Hrkt:Latn:Hepburn-1886")
    end

    it "distinguishes romanizations by system" do
      hepburn = Glossarist::Designation::Expression.from_yaml({
        "type" => "expression",
        "designation" => "Tōkyō",
        "language" => "jpn",
        "script" => "Latn",
        "system" => "Var:jpn-Hrkt:Latn:Hepburn-1886",
      }.to_yaml)
      kunrei = Glossarist::Designation::Expression.from_yaml({
        "type" => "expression",
        "designation" => "Tôkyô",
        "language" => "jpn",
        "script" => "Latn",
        "system" => "Var:jpn-Hrkt:Latn:Kunrei-1937",
      }.to_yaml)
      expect(hepburn.system).not_to eq(kunrei.system)
    end

    it "is available on Symbol via inheritance" do
      sym = Glossarist::Designation::Symbol.from_yaml({
        "type" => "symbol",
        "designation" => "Ω",
        "language" => "grc",
        "script" => "Grek",
      }.to_yaml)
      expect(sym.language).to eq("grc")
      expect(sym.script).to eq("Grek")
    end

    it "is available on LetterSymbol via inheritance" do
      ls = Glossarist::Designation::LetterSymbol.from_yaml({
        "type" => "letter_symbol",
        "designation" => "A",
        "text" => "A",
        "language" => "en",
        "script" => "Latn",
      }.to_yaml)
      expect(ls.language).to eq("en")
      expect(ls.script).to eq("Latn")
    end

    it "is available on GraphicalSymbol via inheritance" do
      gs = Glossarist::Designation::GraphicalSymbol.from_yaml({
        "type" => "graphical_symbol",
        "designation" => "♔",
        "text" => "king",
        "image" => "♔",
        "language" => "eng",
        "script" => "Latn",
      }.to_yaml)
      expect(gs.language).to eq("eng")
      expect(gs.script).to eq("Latn")
    end

    it "is available on Abbreviation via inheritance" do
      abbr = Glossarist::Designation::Abbreviation.from_yaml({
        "type" => "abbreviation",
        "designation" => "UNESCO",
        "language" => "eng",
        "script" => "Latn",
        "acronym" => true,
      }.to_yaml)
      expect(abbr.language).to eq("eng")
      expect(abbr.script).to eq("Latn")
    end
  end

  describe ".infer_designation_type" do
    it "infers abbreviation from abbreviation_type" do
      hash = { "abbreviation_type" => "acronym" }
      expect(described_class.infer_designation_type(hash)).to eq("abbreviation")
    end

    it "infers symbol from international" do
      hash = { "international" => true }
      expect(described_class.infer_designation_type(hash)).to eq("symbol")
    end

    it "infers expression by default" do
      hash = {}
      expect(described_class.infer_designation_type(hash)).to eq("expression")
    end

    it "prioritizes abbreviation_type over international" do
      hash = { "abbreviation_type" => "acronym", "international" => true }
      expect(described_class.infer_designation_type(hash)).to eq("abbreviation")
    end
  end
end

RSpec.describe Glossarist::Designation::Expression do
  subject { described_class.from_yaml(attrs) }

  let(:attrs) do
    { designation: "equality", normative_status: :preferred,
      grammar_info: [{}] }.to_yaml
  end

  it "accepts strings as designations" do
    expect { subject.designation = "new one" }
      .to change { subject.designation }.to("new one")
  end

  it "accepts strings as normative statuses" do
    expect { subject.normative_status = "admitted" }
      .to change { subject.normative_status }.to("admitted")
  end

  it "accepts strings as plurality values" do
    expect { subject.grammar_info.first.number = "plural" }
      .to change { subject.grammar_info.first.number }.to(["plural"])
  end

  it "accepts strings as genders" do
    expect { subject.grammar_info.first.gender = "m" }
      .to change { subject.grammar_info.first.gender }.to(["m"])
  end

  it "accepts strings as parts of speech" do
    expect { subject.grammar_info.first.part_of_speech = "adj" }
      .to change { subject.grammar_info.first.adj }.to(true)
  end

  describe "#field_of_application" do
    it "accepts string values" do
      expect { subject.field_of_application = "in communication theory" }
        .to change {
              subject.field_of_application
            }.to("in communication theory")
    end

    it "round-trips through YAML" do
      src = {
        "type" => "expression",
        "designation" => "information",
        "field_of_application" => "in communication theory",
        "normative_status" => "preferred",
      }.to_yaml

      expr = described_class.from_yaml(src)
      expect(expr.field_of_application).to eq("in communication theory")

      roundtrip = described_class.from_yaml(expr.to_yaml)
      expect(roundtrip.field_of_application).to eq("in communication theory")
    end

    it "reads camelCase YAML key" do
      src = {
        "type" => "expression",
        "designation" => "information",
        "fieldOfApplication" => "in communication theory",
      }.to_yaml

      expr = described_class.from_yaml(src)
      expect(expr.field_of_application).to eq("in communication theory")
    end
  end

  describe "#usage_info" do
    it "round-trips through YAML" do
      src = {
        "type" => "expression",
        "designation" => "test",
        "usage_info" => "science",
      }.to_yaml

      expr = described_class.from_yaml(src)
      expect(expr.usage_info).to eq("science")

      roundtrip = described_class.from_yaml(expr.to_yaml)
      expect(roundtrip.usage_info).to eq("science")
    end
  end

  describe "#to_yaml" do
    it "dumps designation to a hash" do
      attrs.replace({
        designation: "Example designation",
        normative_status: "preferred",
        geographical_area: "somewhere",
        grammar_info: [{
          gender: "m",
          part_of_speech: "adj",
          number: "singular",
        }],
        usage_info: "science",
        field_of_application: "in physics",
      }.to_yaml)

      retval = described_class.from_yaml(subject.to_yaml)

      expect(retval).to be_kind_of(Glossarist::Designation::Expression)
      expect(retval.type).to eq("expression")
      expect(retval.designation).to eq("Example designation")
      expect(retval.normative_status).to eq("preferred")
      expect(retval.geographical_area).to eq("somewhere")
      expect(retval.grammar_info.first.gender).to eq(["m"])
      expect(retval.grammar_info.first.adj).to eq(true)
      expect(retval.grammar_info.first.number).to eq(["singular"])
      expect(retval.usage_info).to eq("science")
      expect(retval.field_of_application).to eq("in physics")
    end
  end

  describe "::from_yaml" do
    it "loads localized concept definition from a hash" do
      src = {
        "type" => "expression",
        "designation" => "Example Designation",
        "normative_status" => "preferred",
      }.to_yaml

      retval = described_class.from_yaml(src)

      expect(retval).to be_kind_of(Glossarist::Designation::Expression)
      expect(retval.designation).to eq("Example Designation")
      expect(retval.normative_status).to eq("preferred")
    end
  end
end

RSpec.describe Glossarist::Designation::Symbol do
  subject { described_class.from_yaml attrs.to_yaml }

  let(:attrs) { { designation: "sym", normative_status: :preferred } }

  it "accepts strings as designations" do
    expect { subject.designation = "new one" }
      .to change { subject.designation }.to("new one")
  end

  it "accepts strings as normative statuses" do
    expect { subject.normative_status = "admitted" }
      .to change { subject.normative_status }.to("admitted")
  end

  describe "#to_yaml" do
    it "dumps designation to a hash" do
      attrs.replace({
                      designation: "X",
                      normative_status: "preferred",
                      geographical_area: "somewhere",
                      international: true,
                    })

      retval = described_class.from_yaml(subject.to_yaml)
      expect(retval).to be_kind_of(Glossarist::Designation::Symbol)
      expect(retval.type).to eq("symbol")
      expect(retval.designation).to eq("X")
      expect(retval.normative_status).to eq("preferred")
      expect(retval.geographical_area).to eq("somewhere")
      expect(retval.international).to be(true)
    end
  end

  describe "::from_yaml" do
    it "loads localized concept definition from a hash" do
      src = {
        "type" => "symbol",
        "designation" => "Example Symbol",
        "normative_status" => "preferred",
      }.to_yaml

      retval = described_class.from_yaml(src)
      expect(retval).to be_kind_of(Glossarist::Designation::Symbol)
      expect(retval.designation).to eq("Example Symbol")
      expect(retval.normative_status).to eq("preferred")
    end
  end
end
