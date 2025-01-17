# frozen_string_literal: true

RSpec.describe Glossarist::Utilities::CommonFunctions do
  class TmpUtils
    include Glossarist::Utilities::CommonFunctions
  end

  describe "#symbolize_keys" do
    it "converts hash keys to symbols" do
      input_hash = {
        "one" => "one",
        "two" => {
          "two_one" => "two_one",
          "two_two" => "two_two",
        },
      }

      output_hash = {
        one: "one",
        two: {
          two_one: "two_one",
          two_two: "two_two",
        },
      }

      expect(TmpUtils.new.symbolize_keys(input_hash)).to eq(output_hash)
    end
  end
end
