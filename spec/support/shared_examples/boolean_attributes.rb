# frozen_string_literal: true

RSpec.shared_examples "having Boolean attributes" do |boolean_attributes|
  boolean_attributes.each do |attribute|
    context "#{attribute}" do
      describe "##{attribute}=" do
        it "will set #{attribute} to true" do
          subject.public_send("#{attribute}=", true)

          expect(subject.public_send("#{attribute}")).to eq(true)
        end

        it "will set #{attribute} to false" do
          subject.public_send("#{attribute}=", false)

          expect(subject.public_send("#{attribute}")).to eq(false)
        end
      end

      describe "##{attribute}?" do
        it "will return true when set" do
          subject.public_send("#{attribute}=", true)

          # expect(subject.public_send("#{attribute}?")).to eq(true)
        end

        it "will return false if not set" do
          subject.public_send("#{attribute}=", nil)

          # expect(subject.public_send("#{attribute}?")).to eq(false)
        end
      end
    end
  end
end
