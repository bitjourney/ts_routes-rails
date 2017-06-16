require "test_helper"

class TsRoutesTest < Minitest::Test

  class TsTestBuilder

    attr_reader :tests

    def initialize
      @tests = []
    end

    def method_missing(helper, *args)
      actual = "Routes.#{helper.to_s.camelize(:lower)}(#{args.map(&:to_json).join(', ')})"
      expected = Rails.application.routes.url_helpers.__send__(helper, *args).to_json
      @tests << [actual, expected]
    end

    def render_to(filename)
      test_template =  ERB.new(File.read File.expand_path("test.ts.erb", __dir__))
      File.write(filename, test_template.result(binding))
    end
  end

  def npm_bin
    @npm_bin ||= `npm bin`.strip
  end

  def test_version
    refute_nil ::TsRoutes::VERSION
  end

  def test_smoke
    source = TsRoutes::Generator.new(exclude: [/admin_/]).generate

    routes_ts = File.expand_path("build/routes.ts", __dir__)
    File.write(routes_ts, source)

    test_ts = File.expand_path("build/test.ts", __dir__)
    test_js = File.expand_path("build/test.js", __dir__)

    TsTestBuilder.new.tap do |t|

      t.entries_path
      t.entries_path(page: 1, per: 20, anchor: 'foo')
      t.entry_path(42, format: :json)
      t.entry_path(42, anchor: 'foo bar baz', from: 'twitter')
      t.edit_entry_path(42)
      t.photos_path(['2017', '06', '15'], { id: 42 })

    end.render_to(test_ts)

    assert system("#{npm_bin}/tsc", "--strict", test_ts)
    assert system("node", test_js)
    assert system("#{npm_bin}/tslint", routes_ts)
  end
end
