# frozen_string_literal: true

RSpec.describe Glossarist::ExpressionDesignation do
  subject { described_class.new attrs }

  let(:attrs) { { designation: "equality", normative_status: "preferred" } }

  it "accepts strings as designations" do
    expect { subject.designation = "new one" }
      .to change { subject.designation }.to("new one")
  end

  it "accepts strings as normative statuses" do
    expect { subject.normative_status = "admitted" }
      .to change { subject.normative_status }.to("admitted")
  end

  it "accepts strings as plurality" do
    expect { subject.plurality = "plural" }
      .to change { subject.plurality }.to("plural")
  end

  it "accepts strings as genders" do
    expect { subject.gender = "m" }
      .to change { subject.gender }.to("m")
  end

  it "accepts strings as part of speech" do
    expect { subject.part_of_speech = "adjective" }
      .to change { subject.part_of_speech }.to("adjective")
  end
end
