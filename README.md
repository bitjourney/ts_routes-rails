# TsRoutes for Rails [![Gem Version](https://badge.fury.io/rb/ts_routes.svg)](https://badge.fury.io/rb/ts_routes) [![Build Status](https://travis-ci.org/bitjourney/ts_routes-rails.svg?branch=master)](https://travis-ci.org/bitjourney/ts_routes-rails)

This gem generates Rails URL helpers in TypeScript, inspired by [js-routes](https://github.com/railsware/js-routes).


## Usage

In your `lib/tasks/ts_routes.rake`:

```ruby:ts_routes.rake

namespace :ts do
  TS_ROUTES_FILENAME = "javascripts/generated/routes.ts"

  desc "Generate #{TS_ROUTES_FILENAME}"
  task routes: :environment do
    Rails.logger.info("Generating #{TS_ROUTES_FILENAME}")
    source = TsRoutes.generate(
        exclude: [/admin/, /debug/],
    )
    File.write(TS_ROUTES_FILENAME, source)
  end
end
```

Then, execute `rake ts:routes` to generate `routes.ts` in your favorite path.

And you can import it in TypeScript code:


```foo.ts
import * as Routes from './generated/RailsRoutes.ts';

console.log(Routes.entriesPath({ page: 1, per: 20 })); // => /entries?page=1&per=20
console.log(Routes.entryPath(1)); // => /entries/1
```

Generated URL helpers are almost compatible with Rails, but they are more strict:

* You must pass required parameters to the helpers as non-named (i.e. normal) arguments
  * i.e. `Routes.entryPath(1)` for `/entries/:id`
  * `Routes.entryPath({ id })` is refused
* You must pass optional parameters as the last argument
  * i.e. `Routes.entriesPath({ page: 1, per: 2 })`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ts_routes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ts_routes

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bitjourney/ts_routes-rails.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
