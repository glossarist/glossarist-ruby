# frozen_string_literal: true

require_relative "../tasks/sync_model"

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
