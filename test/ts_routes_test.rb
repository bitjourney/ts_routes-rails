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

    File.write("#{dir}/routes.ts", source)

    test_ts = File.expand_path("test.ts", __dir__)
    test_js = File.expand_path("test.js", __dir__)

    assert system("node_modules/.bin/tsc", "--strict", test_ts)
    assert system("node", test_js)
  end
end
