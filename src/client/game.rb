#!/usr/bin/ruby
require "rubygems"
require "rubygame"
require "singleton"
require "IRC"

require "game_client"
require "game_event"
require "game_sprite"

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
    @clock.target_framerate = 30
    @clock.enable_tick_events
    
    @list_events = ListEvents.instance
    
    @background = Rubygame::Surface.load("background.jpg")
    @background.blit(@screen, [0, 0])
    
    @sprites = Rubygame::Sprites::Group.new
    Rubygame::Sprites::UpdateGroup.extend_object(@sprites)
    @player = GameSprite.new("mario")
    @sprites << @player
  end
  
  def update
    seconds_passed = @clock.tick.seconds
    
    # aggiunta eventi alla lista
    @ev_raw.each do |event|
      case event
      when Rubygame::Events::QuitRequested
        return false
      when Rubygame::Events::KeyPressed
        return false if event.key == :escape
      when Rubygame::Events::MouseMoved
      when Rubygame::Events::MouseFocusGained
      when Rubygame::Events::MouseFocusLost
      when Rubygame::Events::InputFocusGained
      when Rubygame::Events::InputFocusLost
      else
        @list_events.add_event(GameEvent.fromEvent(event))
      end
    end
    
    # spippolamento lista
    if @list_events.have_event?
      event = @list_events.get_event
      p event
      if event.type == :MousePressed
        @player.move(event.pos)
      end
    end
    
    @sprites.undraw(@screen, @background)
    @sprites.update(seconds_passed)
    @sprites.draw(@screen)
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
