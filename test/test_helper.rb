$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "pp"
require "shellwords"
require "erb"

require "ts_routes"

require "minitest/autorun"

require_relative "./support/application"
