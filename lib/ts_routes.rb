# frozen_string_literal: true

require_relative "./ts_routes/version"
require_relative "./ts_routes/generator"

module TsRoutes
  def self.generate(**opts)
    Generator.new(**opts).generate
  end
end
