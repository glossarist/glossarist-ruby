# frozen_string_literal: true

# Glossarist::Tasks::SyncModel autoloads via lib/glossarist/tasks.rb
# (the immediate-parent namespace file). No `require_relative` here.

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
