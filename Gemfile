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

# Use lutaml-model 0.8 compatible branches for all relaton gems.
# These branches add explicit types to all lutaml-model attributes,
# which is required by lutaml-model 0.8+.
# TODO: Remove these once relaton gems release versions with lutaml-model 0.8 support.
%w[
  relaton relaton-bib relaton-iso
  relaton-3gpp relaton-bipm relaton-bsi relaton-calconnect
  relaton-ccsds relaton-cen relaton-cie relaton-doi relaton-ecma
  relaton-etsi relaton-gb relaton-iana relaton-iec relaton-ieee
  relaton-ietf relaton-iho relaton-isbn relaton-itu relaton-jis
  relaton-nist relaton-oasis relaton-ogc relaton-omg relaton-plateau
  relaton-un relaton-w3c relaton-xsf
].each do |g|
  ref = g == "relaton-bib" ? "upd-lutaml-model-to-0-8-0" : "upd-lutaml-model-to-0.8.0"
  gem g, github: "relaton/#{g}", ref: ref
end

gemspec
