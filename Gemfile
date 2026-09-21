# frozen_string_literal: true
source "https://rubygems.org"
gemspec
gem "canon"
gem "nokogiri"
gem "rake", "~> 13.0"
gem "rdf-turtle", "~> 3.3"
# TEMPORARY: rubyzip ~> 3.7 ships with relaton#178; flip to released monogem on merge.
gem "relaton", github: "relaton/relaton", branch: "fix/rubyzip-open-constraint"
# TEMPORARY: rubyzip-3 + key_value remap fixes are merged on main
# (lutaml-model#830, #840); flip to released on the next lutaml-model release.
gem "lutaml-model", github: "lutaml/lutaml-model", branch: "main"
gem "rspec", "~> 3.0"
gem "rubocop"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
