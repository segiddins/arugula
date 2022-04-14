# Arugula

`Arugula` is a naïve (and incomplete) regular expression implementation written
from scratch on a Friday night.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'arugula'
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install arugula
```

## Usage

```ruby
regexp = Arugula.new('[A-Z][a-z]+')
regexp.match?('ahoy! my name is Samuel') # => 17
regexp.match?('foobar') # => null

regexp = Arugula.new('Hello ([a-z]+)!')
regexp.match('Hello world!') # => #<MatchData "Hello world!" 1:"world">
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bin/rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
run `bundle install`, commit,
and then run `bundle exec rake release`, which will create a git tag for the
version, push git commits and tags,
and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
<https://github.com/segiddins/arugula>.
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
