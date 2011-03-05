#!/usr/bin/ruby
require "rubygems"
require "rubygame"
require "singleton"
require "IRC"

require "game_client"
require "game_event"

class Game
  include Singleton
  
  def initialize
    @screen = Rubygame::Screen.open([640, 480],
                                    0, 
                                    [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF])
    @screen.title = "Game"
    @ev_raw = Rubygame::EventQueue.new
    @ev_raw.enable_new_style_events
    
    @clock = Rubygame::Clock.new
    @clock.target_framerate = 60
    @clock.enable_tick_events
    
    @list_events = ListEvents.instance
    
    # @background = Rubygame::Surface.load("background.jpg")
    # @background.blit(@screen, [0, 0])
  end
  
  def update
    seconds_passed = @clock.tick.seconds
    
    @ev_raw.each do |event|
      #p event
      case event
      when Rubygame::Events::QuitRequested
        return false
      when Rubygame::Events::KeyPressed
        return false if event.key == :escape
        @list_events.add_event(GameEvent.fromEvent(event))
      end
    end
    
    ev = @list_events.get_event
    p ev if ev
    # @sprites.undraw(@screen, @background)
    # @sprites.update(seconds_passed)
    # @sprites.draw(@screen)
    @screen.flip
    
    return true
  end
  
  def quit
    Rubygame.quit
  end
  
end


# MAIN SCRIPT

if __FILE__ == $0
  begin
    GameClient.new("Client_#{rand 1000}", "127.0.0.1", 6667, ["\#Hall"]).connect
  rescue Interrupt
  rescue Exception => e
    puts "MainLoop: " + e.message
    print e.backtrace.join("\n")
    #retry # ritenta dal begin
  ensure
  end
end
