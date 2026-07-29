# frozen_string_literal: true

# Entry-point require triggers the autoload chain
# (Glossarist → Tasks → SyncModel) defined in lib/glossarist.rb.
# Internal-path requires are forbidden by the autoload rule.
require "glossarist"

namespace :glossarist do
  namespace :sync do
    desc "Sync vendored concept-model data from upstream. " \
         "Pass ref=[tag|branch|sha] to pin a specific version."
    task :model, [:ref] do |_t, args|
      ref = args[:ref] || ENV.fetch("REF", nil)
      Glossarist::Tasks::SyncModel.call(ref: ref)
    end
  end
end
