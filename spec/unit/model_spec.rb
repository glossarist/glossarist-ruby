# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Model do
  class ModelSubclass < described_class
    attr_accessor :attr1, :attr2
  end

  describe "#new" do
    it "can be called without arguments" do
      instance = ModelSubclass.new
      expect(instance.attr1).to be(nil)
      expect(instance.attr2).to be(nil)
    end

    it "can be called with attribute hash" do
      instance = ModelSubclass.new({ attr1: 1, attr2: 2 })
      expect(instance.attr1).to be(1)
      expect(instance.attr2).to be(2)
    end

    it "return attributes if not a hash" do
      object = ModelSubclass.new(attr1: 1, attr2: 2)
      instance = ModelSubclass.new(object)
      expect(instance).to be(object)
    end

    it "raises error when attribute hash includes unknown attributes" do
      expect { ModelSubclass.new({ attr1: 1, attr2: 2, attr3: 3 }) }
        .to raise_error(ArgumentError, /attr3/)
    end
  end

  describe "#set_attribute" do
    it "sets given attribute to a given value" do
      instance = ModelSubclass.new
      expect { instance.set_attribute "attr1", 1 }
        .to change { instance.attr1 }.to(1)
      expect { instance.set_attribute :attr2, 2 }
        .to change { instance.attr2 }.to(2)
    end

    it "raises error on unknown attribute" do
      instance = ModelSubclass.new
      expect { instance.set_attribute "attr3", 3 }
        .to raise_error(ArgumentError, /attr3/)
    end
  end
end
