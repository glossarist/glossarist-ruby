# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "spec_helper"
require "open3"

RSpec.describe "YAML adapter selection" do
  # The bootstrap runs at require time, so override behavior is observable
  # only in a fresh process.
  def adapter_in_fresh_process(env)
    out, status = Open3.capture2(
      env, RbConfig.ruby, "-Ilib",
      "-e", 'require "glossarist"; print Lutaml::Model::Config.instance.yaml_adapter',
    )
    expect(status).to be_success
    out
  end

  it "selects the yeptris lane by default" do
    expect(Lutaml::Model::Config.instance.yaml_adapter.name)
      .to end_with("YeptrisAdapter")
  end

  it "keeps lutaml-model's default when the host opts out via FONTIST_YAML" do
    expect(adapter_in_fresh_process("FONTIST_YAML" => "psych"))
      .to end_with("StandardAdapter")
  end
end
