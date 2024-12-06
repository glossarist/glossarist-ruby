# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Config do
  subject { described_class.instance }

  it "is a singleton class" do
    expect(subject).to eq(described_class.instance)
  end

  context ".register_extension_attributes" do
    before(:each) do
      @extension_attributes = subject.extension_attributes.dup
    end

    after(:each) do
      described_class.register_extension_attributes(@extension_attributes)
    end

    it "registers extension attributes" do
      expect { described_class.register_extension_attributes(["foo", "bar"]) }
        .to change { described_class.extension_attributes }
        .from([])
        .to(["foo", "bar"])
    end
  end

  context ".register_class" do
    before(:each) do
      @registered_classes = subject.registered_classes.dup
    end

    after(:each) do
      subject.instance_variable_set(:@registered_classes, @registered_classes)
    end

    it "registers custom classes with string names" do
      expect { described_class.register_class("foo", Array) }
        .to change { described_class.class_for("foo") }
        .from(nil)
        .to(Array)
    end

    it "registers custom class for managed_concept" do
      expect { described_class.register_class("managed_concept", Array) }
        .to change { described_class.class_for("managed_concept") }
        .from(Glossarist::LutamlModel::ManagedConcept)
        .to(Array)
    end

    it "registers custom classes with symbol names" do
      expect { described_class.register_class(:foo, Array) }
        .to change { described_class.class_for(:foo) }
        .from(nil)
        .to(Array)
    end
  end
end
