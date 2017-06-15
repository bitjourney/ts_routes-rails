$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "pp"
require "rails/all"

require "ts_routes"

require "minitest/autorun"

class App < Rails::Application
  config.root = File.expand_path("./dummy", __dir__)
end

require_relative "./dummy/config/routes"