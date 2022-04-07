# frozen_string_literal: true

RSpec.describe Glossarist::Utilities::Enum::InstanceMethods do
  class TmpInstanceClass
    include Glossarist::Utilities::Enum::InstanceMethods
    extend Glossarist::Utilities::Enum::ClassMethods
  end

  let!(:subject) { TmpInstanceClass.new }

  describe "#selected_type" do
    context "no type is registered" do
      it "returns empty hash" do
        expect(subject.selected_type).to eq({})
      end
    end

    context "status and number are registered" do
      before(:all) do
        TmpInstanceClass.register_enum(:status, %i[active inactive])
        TmpInstanceClass.register_enum(:number, %i[singular dual plural], multiple: true)
      end

      context "nothing is selected" do
        it "returns status: [], number: []" do
          expect(subject.selected_type).to eq({ status: [], number: [] })
        end
      end

      context "status: active is selected" do
        it "returns status as active" do
          subject.active = true
          expect(subject.selected_type).to eq({ status: [:active], number: [] })
        end
      end
    end

    describe "#select_type" do
      it "should select status as active when passed as single value" do
        expect(subject.active?).to eq(false)
        expect(subject.inactive?).to eq(false)

        subject.select_type(:status, :active)

        expect(subject.active?).to eq(true)
        expect(subject.inactive?).to eq(false)
      end

      it "should select status as active when passed as array" do
        expect(subject.active?).to eq(false)
        expect(subject.inactive?).to eq(false)

        subject.select_type(:status, [:active])

        expect(subject.active?).to eq(true)
        expect(subject.inactive?).to eq(false)
      end

      it "should select multiple numbers" do
        expect(subject.singular?).to eq(false)
        expect(subject.dual?).to eq(false)
        expect(subject.plural?).to eq(false)

        subject.select_type(:number, %i[dual plural])

        expect(subject.singular?).to eq(false)
        expect(subject.dual?).to eq(true)
        expect(subject.plural?).to eq(true)
      end
    end

    describe "#deselect_type" do
      it "should deselect status active type" do
        subject.select_type(:status, :active)

        expect(subject.active?).to eq(true)
        expect(subject.inactive?).to eq(false)

        subject.deselect_type(:status, :active)

        expect(subject.active?).to eq(false)
        expect(subject.inactive?).to eq(false)
      end
    end

    describe "#select_type_value" do
      it "will select if the type and value is valid" do
        expect(subject.active?).to eq(false)
        expect(subject.inactive?).to eq(false)

        subject.send(:select_type_value, :status, :active)

        expect(subject.active?).to eq(true)
        expect(subject.inactive?).to eq(false)
      end

      it "will unset if nil is passed as value" do
        subject.active = true

        expect(subject.active?).to eq(true)
        expect(subject.inactive?).to eq(false)

        subject.send(:select_type_value, :status, nil)

        expect(subject.active?).to eq(false)
        expect(subject.inactive?).to eq(false)
      end

      it "will raise Glossarist::InvalidTypeError if type is not valid" do
        expect { subject.send(:select_type_value, :status, :foo) }.to raise_error(Glossarist::InvalidTypeError)
      end
    end
  end
end
