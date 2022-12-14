require "fiber" # for Ruby < 3.0
require "set"
require_relative "fake_sonic_pi/version"
require_relative "fake_sonic_pi/events"

class FakeSonicPi
  class NoSleep < StandardError; end

  attr_reader :output

  def initialize(&definition)
    @definition = definition
    @output = Events.new
    @events = Events.new
    @beat = 0.0
    @fibers = {}
  end

  # MAGIC :D I mean Fibers ;)
  def run(beats, events: [])
    @events.add_batch(events)
    instance_eval(&@definition)
    loop do
      # remove terminated fibers (`at` blocks that already ran)
      @fibers.select! { |f, _b| f.alive? }

      # split fibers waiting for an event, and fibers scheduled for a particular
      # beat (sleeping or scheduled with `at`)
      waiting_fibers, scheduled_fibers = @fibers.partition { |_f, b| b.nil? }

      # from the scheduled ones, remove those scheduled for after the max number of beats
      scheduled_fibers.reject! { |_f, b| b > beats }

      # give all waiting fibers a chance
      events_before = @events.dup
      waiting_fibers.each do |f, _b|
        @fibers[f] = f.resume
      end
      # if any of them added an event, do it again
      next if events_before != @events

      # find next scheduled fiber (and for when is it scheduled?)
      next_fiber, next_beat = scheduled_fibers.min_by { |_f, beat| beat }

      # is there any event to happen before next_beat? if so, process that before
      next_beat_with_event = @events.next_beat(@beat)
      if next_beat_with_event && (next_beat.nil? || next_beat_with_event < next_beat)
        @beat = next_beat_with_event
        next
        # otherwise proceed with the next scheduled fiber
      elsif next_fiber
        @beat = next_beat
        @fibers[next_fiber] = next_fiber.resume
        # and if there is none, then we're done \o/
      else
        break
      end
    end
  end

  def live_loop(name, &block)
    # create a fiber that runs the block repeatedly...
    f = Fiber.new do
      loop do
        Thread.current[:slept] = false
        block.call
        raise NoSleep, "live_loop #{name} didn't sleep" unless Thread.current[:slept]
      end
    end
    # ...and schedule it for now
    @fibers[f] = @beat
  end

  # sleep the fast way ;)
  def sleep(n)
    Thread.current[:slept] = true
    Fiber.yield @beat + n
  end

  def at(*beats, &block)
    # for each specified beat, create a fiber that calls the block once, and
    # schedule it for then.
    beats.each do |beat|
      f = Fiber.new(&block)
      @fibers[f] = @beat + beat
    end
  end

  def sync(event_name)
    loop do
      Thread.current[:slept] = true
      # find event in current beat and return its value, otherwise let the other
      # fibers progress, then try again
      if (event = @events.find(@beat, event_name))
        event.processed_by << Fiber.current
        return event.value
      else
        Fiber.yield nil
      end
    end
  end

  def get(name, default = nil)
    if (event = @events.most_recent(@beat, name))
      event.value
    else
      default
    end
  end

  def set(name, value)
    @events.add(@beat, name, value)
  end

  alias_method :cue, :set

  def in_thread
    # just do it ;) fibers are awesome :D
    yield
  end

  def stop
    # kind of stop :D
    sleep Float::INFINITY
  end

  # commands we store as output, returning a (fake) node
  %i[play sample synth control midi_note_on set_volume!].each do |command|
    define_method(command) do |*args|
      @output.add @beat, command, args
      Node.new(command, args)
    end
  end

  def with_fx(*args, &block)
    block.call(Node.new(:fx, args))
  end

  Node = Struct.new(:command, :args) do
    def kill
      # no-op
    end
  end

  # no-ops (sonic pi commands whose effect is not relevant here, but need to be
  # implemented so that the test doesn't fail)
  %i[use_real_time].each do |cmd|
    define_method(cmd) { |*_args| }
  end

  def include(*args)
    self.class.include(*args)
  end
end
