#!/usr/bin/ruby
require "rubygems"
require "rubygame"
require "IRC"
require "singleton"

class Game
  include Singleton
  
  def initialize
    @screen = Rubygame::Screen.open([640, 480],
                                    0, 
                                    [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF])
    @screen.title = "Hello Rubygame World!"
    @event_queue = Rubygame::EventQueue.new
    @event_queue.enable_new_style_events
    
    @clock = Rubygame::Clock.new
    @clock.target_framerate = 30
    @clock.enable_tick_events
        
    @background = Rubygame::Surface.load("background.jpg")
    @background.blit(@screen, [0, 0])
  end
  
  def tick
    seconds_passed = @clock.tick().seconds
    
    @event_queue.each do |event|
      case event
      when Rubygame::Events::QuitRequested, Rubygame::Events::KeyReleased
        
      end
      # @list << Event.new(event)
    end
    
    # @sprites.undraw(@screen, @background)
    # @sprites.update(seconds_passed)
    # @sprites.draw(@screen)
    @screen.flip  
  end
  
end

class IRCConnection
  
  def IRCConnection.main
    while(@@quit == 0)
      do_one_loop { |event|
        yield event
      }
      Game.instance.tick
    end
  end
  
end

class Client < IRC
  
  def initialize(nick, server, port, channels = [], options = {})
    super(nick, server, port, nil, options)
    # Callbakcs for the connection.
    IRCEvent.add_callback("endofmotd") do |event| 
      channels.each { |chan| add_channel(chan) }
      # puts Game.instance
    end
    IRCEvent.add_callback("nicknameinuse") do |event| 
      ch_nick("RubyBot")
    end
    IRCEvent.add_callback("privmsg") do |event| 
      parse(event)
    end
    IRCEvent.add_callback("join") do |event| 
      if @autoops.include?(event.from)
        op(event.channel, event.from)
      end
    end
  end
  
  def parse(event)
  end
  
end


# MAIN SCRIPT

if __FILE__ == $0
  begin
    Client.new("Client", "127.0.0.1", 6667, ["\#Hall"]).connect
  rescue Interrupt
  rescue Exception => e
    puts "MainLoop: " + e.message
    print e.backtrace.join("\n")
    #retry # ritenta dal begin
  ensure
  end
end
