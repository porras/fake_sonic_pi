# frozen_string_literal: true
require 'fake_sonic_pi/rspec'

RSpec.describe FakeSonicPi do
  it "has a version number" do
    expect(FakeSonicPi::VERSION).not_to be nil
  end

  # Used to test drive the first implementation, it doesn't cover it all. This
  # class was extracted from https://github.com/porras/sonic-pi-akai-apc-mini
  # and most of it (other than this super basic test) was covered implicitly by
  # its tests. Little by little everything should get covered here.
  example 'basic test' do
    sp = FakeSonicPi.new do
      live_loop :drums do
        sample :bd_haus
        sleep 0.5
      end

      live_loop :bass do
        play :c2
        sleep 1
      end
    end

    sp.run(2)

    expect(sp).to have_output(:sample, :bd_haus).at(0, 0.5, 1, 1.5)
    expect(sp).to have_output(:play, :c2).at(0, 1)
  end

  it 'allows including modules' do
    mod = Module.new do
      def play_bass(note)
        play note - 12
      end
    end

    sp = FakeSonicPi.new do
      include mod

      live_loop :bass do
        play_bass 24
        sleep 1
      end
    end

    sp.run(2)

    expect(sp).to have_output(:play, 12).at(0, 1)
  end
end
