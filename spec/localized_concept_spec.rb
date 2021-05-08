# frozen_string_literal: true

RSpec.describe Glossarist::LocalizedConcept do
  subject { described_class.new attrs }

  let(:attrs) { { language_code: "eng" } }

  it "accepts strings as ids" do
    expect { subject.id = "456" }
      .to change { subject.id }.to("456")
  end

  it "accepts strings as language codes" do
    expect { subject.language_code = "deu" }
      .to change { subject.language_code }.to("deu")
  end

  it "accepts strings as definitions" do
    expect { subject.definition = "this is very important" }
      .to change { subject.definition }.to("this is very important")
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
      .to change { subject.review_date }.to("2020-01-01")
  end

  it "accepts strings as review decision dates" do
    expect { subject.review_decision_date = "2020-01-01" }
      .to change { subject.review_decision_date }.to("2020-01-01")
  end

  it "accepts strings as review decision events" do
    expect { subject.review_decision_event = "published" }
      .to change { subject.review_decision_event }.to("published")
  end

  it "accepts strings as dates accepted" do
    expect { subject.date_accepted = "2020-01-01" }
      .to change { subject.date_accepted }.to("2020-01-01")
  end

  it "accepts strings as dates amended" do
    expect { subject.date_amended = "2020-01-01" }
      .to change { subject.date_amended }.to("2020-01-01")
  end

  describe "#terms" do
    let(:expression) { Glossarist::ExpressionDesignation.new }

    it "is an array of designations" do
      expect { subject.terms << expression }
        .to change { subject.terms }.to([expression])
    end
  end

  describe "#notes" do
    it "is an array of strings" do
      expect { subject.notes << "str" }
        .to change { subject.notes }.to(["str"])
    end
  end

  describe "#examples" do
    it "is an array of strings" do
      expect { subject.examples << "str" }
        .to change { subject.examples }.to(["str"])
    end
  end
end
