module Glossarist
  class Asset < Lutaml::Model::Serializable
    attribute :path, :string

    key_value do
      map :path, to: :path
    end

    def eql?(asset)
      path == asset.path
    end

    def hash
      path.hash
    end
  end
end
