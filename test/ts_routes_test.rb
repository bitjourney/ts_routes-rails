require "test_helper"
require "shellwords"

class TsRoutesTest < Minitest::Test

  def dir
    File.expand_path("build", __dir__)
  end

  def tsc(source)
    ts_file = Tempfile.new(['routes', '.ts'])
    ts_file.write(source)

    output = `$(npm bin)/tsc --strict #{Shellwords.escape(ts_file.path)} 2>&1`
    ts_file.delete
    output
  end

  def test_version
    refute_nil ::TsRoutes::VERSION
  end

  def test_smoke
    source = TsRoutes::Generator.new(exclude: [/admin_/]).generate

    routes_ts = File.expand_path("build/routes.ts", __dir__)
    test_ts = File.expand_path("test.ts", __dir__)
    test_js = File.expand_path("test.js", __dir__)

    File.write(routes_ts, source)

    assert system("node_modules/.bin/tsc", "--strict", test_ts)
    assert system("node", test_js)
    assert system("node_modules/.bin/tslint", routes_ts)
  end
end
