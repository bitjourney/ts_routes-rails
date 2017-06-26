require "test_helper"

class TsRoutesTest < Minitest::Test

  class TsTestBuilder

    attr_reader :tests

    def initialize
      @tests = []
    end

    def method_missing(helper, *args)
      actual = "Routes.#{helper.to_s.camelize(:lower)}(#{args.map(&:to_json).join(', ')})"

      if (matched = /^dashboard_app_(.*)/.match(helper))
        expected = DashboardEngine.routes.url_helpers.__send__(matched[1], *args)
      else
        expected = Rails.application.routes.url_helpers.__send__(helper, *args)
      end
      @tests << [actual, expected.to_json]
    end

    def render_to(filename)
      test_template =  ERB.new(File.read File.expand_path("test.ts.erb", __dir__))
      File.write(filename, test_template.result(binding))
    end
  end

  def npm_bin
    @npm_bin ||= `npm bin`.strip
  end

  def relative_path(path)
    File.expand_path(path, __dir__)
  end

  def test_version
    refute_nil ::TsRoutes::VERSION
  end

  def test_smoke
    source = TsRoutes.generate(
      exclude: [/admin_/],
      header: "/* tslint:disable:max-line-length variable-name whitespace */"
    )

    routes_ts = relative_path("build/routes.ts")
    File.write(routes_ts, source)

    tsconfig = relative_path("build/tsconfig.json")
    FileUtils.copy_file(relative_path("support/tsconfig.json"), tsconfig)

    test_ts = relative_path("build/test.ts")
    test_js = relative_path("build/test.js")

    TsTestBuilder.new.tap do |t|

      t.root_path
      t.entries_path
      t.entries_path(page: 1, per: 20, anchor: 'foo')
      t.entries_path(q: '')
      t.entries_path(q: nil)
      t.entry_path(42, format: :json)
      t.entry_path(42, anchor: 'foo bar baz', from: 'twitter')
      t.entry_path(42, 'foo/bar': 'hoge=fuga')
      t.entry_path(42, foo: [1, 2, 3])
      t.entry_path(42, foo: [[1, 2, 3], [10, 20, 30]])
      t.entry_path(42, foo: { bar: true, baz: false })
      t.entry_path(42, foo: { bar: { x: true }, baz: [1, 2,3] })

      t.edit_entry_path(42)
      t.photos_path(['2017', '06', '15'], { id: 42 })
      t.photos_path(['2017', '06', '15'], { id: nil })

      t.settings_path

      t.entry_like_path(42)

      t.dashboard_app_resource_path(42)
      t.hello_path

    end.render_to(test_ts)

    assert system("#{npm_bin}/tsc", "--project", tsconfig)
    assert system("node", test_js)
    assert system("#{npm_bin}/tslint", "--type-check", "--project", tsconfig)
  end
end
