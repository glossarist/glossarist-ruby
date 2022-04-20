# frozen_string_literal: true

RSpec.shared_examples "an Enum" do
  described_class.enums.each do |name, enum|
    enum[:registered_values].each do |value|
      describe "##{value}?" do
        context "when #{value} is set to `true`" do
          it "will return `true`" do
            subject.public_send("#{value}=", true)
            expect(subject.public_send("#{value}?")).to eq(true)
          end
        end

        context "when #{value} is set to `false`" do
          it "will return `false`" do
            subject.public_send("#{value}=", false)
            expect(subject.public_send("#{value}?")).to eq(false)
          end
        end
      end
    end
  end

  described_class.registered_enums.each do |type|
    describe "##{type}=" do
      let!(:valid_type) { described_class.enums[type][:registered_values].first&.to_s }

      context "when type is valid" do
        it "will set the type" do
          subject.public_send("#{type}=", valid_type)

          expect(subject.public_send("#{valid_type}?")).to eq(true)
          if described_class.enums[type][:options][:multiple]
            expect(subject.public_send("#{type}")).to eq([valid_type])
          else
            expect(subject.public_send("#{type}")).to eq(valid_type)
          end
        end
      end

      context "when type is invalid" do
        it "will raise error" do
          expect { subject.public_send("#{type}=", "invalid type") }.to raise_error(Glossarist::InvalidTypeError)
        end
      end
    end
  end
end
