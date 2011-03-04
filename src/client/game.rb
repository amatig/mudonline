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
    @event_queue = Rubygame::EventQueue.new
    @event_queue.enable_new_style_events
    
    @clock = Rubygame::Clock.new
    @clock.target_framerate = 30
    @clock.enable_tick_events
    
    @game_events = []
    
    # @background = Rubygame::Surface.load("background.jpg")
    # @background.blit(@screen, [0, 0])
  end
  
  def update
    seconds_passed = @clock.tick.seconds
    
    @event_queue.each do |event|
      #p event
      case event
      when Rubygame::Events::QuitRequested
        return false
      when Rubygame::Events::KeyReleased
        return false if event.key == :escape
      end
      @game_events << GameEvent.fromEvent(event)
    end
    
    puts get_event
    # @sprites.undraw(@screen, @background)
    # @sprites.update(seconds_passed)
    # @sprites.draw(@screen)
    @screen.flip
    
    return true
  end
  
  def get_event
    temp = nil
    @game_events.each do |e|
      if (Time.now.to_i - e.timeout >= 0)
        temp = e
        break
      end
    end
    if temp
      @game_events.delete(temp)
      puts temp.inspect
    end
    return temp
  end
  
  def add_event(event)
    @game_events << event
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
