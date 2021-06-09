module FixturesHelper
  def fixtures_path
    File.expand_path("../fixtures", __dir__)
  end
end

RSpec.configure do |c|
  c.include FixturesHelper
end
