# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

require "spec_helper"
require "open3"

RSpec.describe "YAML adapter selection" do
  # The bootstrap runs at require time, so override behavior is observable
  # only in a fresh process.
  def adapters_in_fresh_process(env)
    out, status = Open3.capture2(
      env, RbConfig.ruby, "-Ilib",
      "-e", 'require "glossarist"; print Lutaml::Model::Config.instance' \
            '.yaml_adapter.name.split("::").last << " " << ' \
            'Lutaml::Model::Config.instance.get_adapter(:yamls)' \
            '.name.split("::").last',
    )
    expect(status).to be_success
    out.split
  end

  it "selects the yeptris lanes by default (single-doc and stream)" do
    expect(adapters_in_fresh_process({}))
      .to eq(%w[YeptrisAdapter YeptrisAdapter])
  end

  it "keeps lutaml-model's defaults when the host opts out via FONTIST_YAML" do
    expect(adapters_in_fresh_process("FONTIST_YAML" => "psych"))
      .to eq(%w[StandardAdapter StandardAdapter])
  end

  it "keeps lutaml-model's defaults when the host opts out via LUTAML_YAML" do
    expect(adapters_in_fresh_process("LUTAML_YAML" => "psych"))
      .to eq(%w[StandardAdapter StandardAdapter])
  end
end
