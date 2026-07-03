# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "glossarist/cli/export_command"

RSpec.describe Glossarist::CLI::ExportCommand, "#run with --per-concept" do
  let(:fixtures_dir) { fixtures_path("concept_collection_v2") }

  around do |ex|
    @tmpdir = Dir.mktmpdir
    ex.run
    FileUtils.rm_rf(@tmpdir)
  end

  let(:tmpdir) { @tmpdir }

  def run!(**overrides)
    options = { format: "turtle", output: tmpdir, shortname: "test" }
    described_class.new(fixtures_dir, options.merge(overrides)).run
  end

  it "emits one .ttl per concept under concepts/" do
    run!(format: "turtle", per_concept: true, aggregate: false)
    files = Dir.glob(File.join(tmpdir, "concepts", "*.ttl"))
    expect(files.length).to be >= 1
  end

  it "emits one .jsonld per concept under concepts/" do
    run!(format: "jsonld", per_concept: true, aggregate: false)
    files = Dir.glob(File.join(tmpdir, "concepts", "*.jsonld"))
    expect(files.length).to be >= 1
    sample = JSON.parse(File.read(files.first))
    expect(sample["@graph"]).to be_an(Array)
  end

  it "emits one .yaml per concept under concepts/" do
    run!(format: "yaml", per_concept: true, aggregate: false)
    files = Dir.glob(File.join(tmpdir, "concepts", "*.yaml"))
    expect(files.length).to be >= 1
  end

  it "emits aggregate alongside per-concept when both flags set" do
    run!(format: "turtle", per_concept: true, aggregate: true)
    expect(File.exist?(File.join(tmpdir, "test.ttl"))).to be(true)
    expect(Dir.glob(File.join(tmpdir, "concepts", "*.ttl")).length).to be >= 1
  end

  it "raises ArgumentError on per-concept tbx (unsupported)" do
    expect { run!(format: "tbx", per_concept: true, aggregate: false) }
      .to raise_error(SystemExit)
  end

  it "accepts comma-separated --format" do
    run!(format: "turtle,jsonld", per_concept: false, aggregate: true)
    expect(File.exist?(File.join(tmpdir, "test.ttl"))).to be(true)
    expect(File.exist?(File.join(tmpdir, "test.jsonld"))).to be(true)
  end

  it "rejects unknown formats" do
    expect { run!(format: "nope") }
      .to raise_error(SystemExit)
  end
end
