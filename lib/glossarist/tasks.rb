# frozen_string_literal: true

module Glossarist
  # Rake-task namespace for vendored-data sync + SHACL validation.
  # Loaded lazily via autoload from lib/glossarist.rb.
  module Tasks
    autoload :SyncModel, "glossarist/tasks/sync_model"
  end
end
