# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::OrphanedImagesRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-021")
    expect(rule.category).to eq(:references)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when the asset index is empty" do
    expect(rule).not_to be_applicable(dataset_context)
  end

  context "with an images/ directory and a concept" do
    before do
      images_dir = File.join(tmpdir, "images")
      FileUtils.mkdir_p(images_dir)
      File.write(File.join(images_dir, "referenced.png"), "png",
                 encoding: "utf-8")
      File.write(File.join(images_dir, "orphaned.png"), "png",
                 encoding: "utf-8")
      # Rebuild dataset_context so asset_index picks up the new files.
      @dataset_context = make_dataset_context(tmpdir)
      referrer = make_managed_concept(id: "x", langs: {
                                        eng: { definition: [{ "content" => "image::referenced.png[]" }] },
                                      })
      @dataset_context.add_concept(referrer)
    end

    let(:dataset_context) { @dataset_context }

    it "flags the image not referenced by any concept" do
      issues = rule.check(dataset_context)
      orphaned = issues.map(&:message).join("\n")
      expect(orphaned).to include("orphaned.png")
      expect(orphaned).not_to include("referenced.png")
    end
  end
end
