# FakeSonicPi

`FakeSonicPi` is a small utility class used to test Sonic Pi related code. It
implements a tiny subset of its API in a silent (yep, no sound) and
instant-running (as opposed to the real Sonic Pi, which is supposed to keep
running indefinitely). It was originally part of the test suite of
[sonic-pi-akai-apc-mini](https://github.com/porras/sonic-pi-akai-apc-mini), so
it implements only a very small part of the Sonic Pi API, focusing on timing
(being able to check what happens at which time). Since extracting, I've also
used it to test [ptn](https://github.com/porras/ptn) and added a couple of
features needed for it.

If that doesn't make much sense, have a look at the examples in this README, the
tests in `spec/`, and the tests of the projects that use it.

## Installation

Install the gem and add to the library's Gemfile by executing:

    $ bundle add fake_sonic_pi

## Usage

You need to start by requiring it in your test, your `test_helper.rb`, or
`spec_helper.rb`. Then, you can use it to define a Sonic Pi program, in a block.
That would be what you would type on a Sonic Pi buffer:

```ruby
sp = FakeSonicPi.new do
  live_loop :drums do
    sample :bd_haus
    sleep 0.5
  end
end
```

Then, you can _run_ it (you don't really run it but **simulate** it) for a number of beats:

```ruby
sp.run(2)
```

After doing that, the `sp` object has an `output`, which contains the sounds
(and other events that your code has produced), associated to the timing where
they happened:

```
#<FakeSonicPi::Events:0x000055ac84368978
 @events=
  [[0.0,
    #<struct FakeSonicPi::Events::Event
     name=:sample,
     value=[:bd_haus],
     processed_by=#<Set: {}>>],
   [0.5,
    #<struct FakeSonicPi::Events::Event
     name=:sample,
     value=[:bd_haus],
     processed_by=#<Set: {}>>],
   [1.0,
    #<struct FakeSonicPi::Events::Event
     name=:sample,
     value=[:bd_haus],
     processed_by=#<Set: {}>>],
   [1.5,
    #<struct FakeSonicPi::Events::Event
     name=:sample,
     value=[:bd_haus],
     processed_by=#<Set: {}>>],
   [2.0,
    #<struct FakeSonicPi::Events::Event
     name=:sample,
     value=[:bd_haus],
     processed_by=#<Set: {}>>]]>
```

You can use this object to check that your code did what it should. The internal
structure is as follows (as you can see in the inspect output above):

* It has an `events` attribute, which is an array of pairs
* In each pair:
  * The first element is a `Float`, referencing the beat in which the event happened.
  * The second one is an `Event` object, with the following attributes:
    * `name`: the type of event: `:play`, `:sample`, `:midi_note_on`, ...
      (basically the Sonic Pi command that was called).
    * `value`: an array with the arguments passed to that command (the sample
      name, the note, etc.).

So you can check that your example produced one `:bd_haus` sound each half beat with something like this:

```ruby
assert_equal 5, sp.output.events.size

beat, event = sp.output.events[0]
assert_equal 0.0, beat
assert_equal :sample, event.name
assert_equal :bd_haus, event.value.first
```

### RSpec

If you use RSpec, a matcher is provided to make such assertions simpler. Require
`fake_sonic_pi/rspec` in your `spec_helper.rb` and you can do the following:

```ruby
expect(sp).to have_output(:sample, :bd_haus).at(0, 0.5, 1, 1.5, 2)
```

Check the `spec/` directory for more examples.

### Implemented subset / Limitations

The following commands of the API are implemented:

* `play`
* `sample`
* `sleep`
* `at`
* `midi_note_on` / `midi_note_off`
* `get` / `set` / `cue` / `sync`
* `stop`
* `in_thread` (but not completely, so depending on what you do in the thread, it might not work as expected)
* `live_loop` (but not the `sync` option)
* `with_fx`
* `control`
* `set_volume!`

The main limitation is that several commands (prominently `sleep`) don't work if
they're not inside a `live_loop`. This is quite different of the real Sonic Pi,
where such limitation doesn't exist, but it is in general possible to write your
tests using `live_loop`s, so, at least for the libraries I've used FakeSonicPi
with, it is not such a big deal.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/porras/fake_sonic_pi. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of
conduct](https://github.com/porras/fake_sonic_pi/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FakeSonicPi project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/porras/fake_sonic_pi/blob/main/CODE_OF_CONDUCT.md).
