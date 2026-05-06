# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "canon"
gem "lutaml-model", "~> 0.8.0"
gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
gem "tbx", "~> 0.1"

# Override relaton gems with lutaml-model 0.8 compatible versions.
# Released 2.0.0 gems have untyped lutaml-model attributes that fail with 0.8+.
# lutaml-integration branches have typed attributes and relaton-bib ~> 2.1.0.
# TODO: Remove once relaton gems release versions with lutaml-model 0.8 support.
gem "relaton-3gpp", github: "relaton/relaton-3gpp",
                    branch: "lutaml-integration"
gem "relaton-bib", github: "relaton/relaton-bib", branch: "lutaml-integration"
gem "relaton-bipm", github: "relaton/relaton-bipm",
                    branch: "lutaml-integration"
gem "relaton-bsi", github: "relaton/relaton-bsi", branch: "lutaml-integration"
gem "relaton-calconnect", github: "relaton/relaton-calconnect",
                          branch: "lutaml-integration"
gem "relaton-ccsds", github: "relaton/relaton-ccsds",
                     branch: "lutaml-integration"
gem "relaton-cen", github: "relaton/relaton-cen", branch: "lutaml-integration"
gem "relaton-iec", github: "relaton/relaton-iec", branch: "lutaml-integration"
gem "relaton-iso", github: "relaton/relaton-iso", branch: "lutaml-integration"
gem "relaton-itu", github: "relaton/relaton-itu", branch: "lutaml-integration"
