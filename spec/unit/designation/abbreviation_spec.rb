# frozen_string_literal: true

RSpec.describe Glossarist::Designation::Abbreviation do
  describe "#acronym?" do
    context "when acronym is set to `true`" do
      it "will return `true`" do
        subject.acronym = true
        expect(subject.acronym?).to eq(true)
      end
    end

    context "when acronym is set to `false`" do
      it "will return `false`" do
        subject.acronym = false
        expect(subject.acronym?).to eq(false)
      end
    end
  end

  describe "#truncation?" do
    context "when truncation is set to `true`" do
      it "will return `true`" do
        subject.truncation = true
        expect(subject.truncation?).to eq(true)
      end
    end

    context "when truncation is set to `false`" do
      it "will return `false`" do
        subject.truncation = false
        expect(subject.truncation?).to eq(false)
      end
    end
  end

  describe "#initialism?" do
    context "when initialism is set to `true`" do
      it "will return `true`" do
        subject.initialism = true
        expect(subject.initialism?).to eq(true)
      end
    end

    context "when initialism is set to `false`" do
      it "will return `false`" do
        subject.initialism = false
        expect(subject.initialism?).to eq(false)
      end
    end
  end

  describe "#type=" do
    context "when type is valid" do
      it "will set the type" do
        subject.type = "acronym"

        expect(subject.acronym?).to eq(true)
        expect(subject.type).to eq(:acronym)
      end
    end

    context "when type is invalid" do
      it "will raise error" do
        expect { subject.type = "invalid type" }.to raise_error(subject.class::InvalidTypeError)
      end
    end
  end
end
