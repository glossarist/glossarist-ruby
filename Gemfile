# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "canon"
gem "lutaml-model", github: "lutaml/lutaml-model", ref: "main"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"

# Override relaton gems from fix/lutaml-model-0.8 branches where available.
# Released 2.0.0 gems have untyped lutaml-model attributes that fail with 0.8+.
# fix/lutaml-model-0.8 branches keep version 2.0.0 (compatible) + lutaml-model ~> 0.8.
# TODO: Remove once relaton gems release versions with lutaml-model 0.8 support.
gem "relaton-bib", github: "relaton/relaton-bib", branch: "fix/lutaml-model-0.8"
gem "relaton-iso", github: "relaton/relaton-iso", branch: "fix/lutaml-model-0.8"
gem "relaton-3gpp", github: "relaton/relaton-3gpp", branch: "fix/lutaml-model-0.8"
gem "relaton-bipm", github: "relaton/relaton-bipm", branch: "fix/lutaml-model-0.8"
gem "relaton-bsi", github: "relaton/relaton-bsi", branch: "fix/lutaml-model-0.8"
