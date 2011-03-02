#!/usr/bin/env ruby

require "rubygems"
require "rubygame"

# Open a window with a drawable area measuring 640x480 pixels 
@screen = Rubygame::Screen.open([640, 480])

# Set the title of the window
@screen.title = "Hello Rubygame World!"

# Create a queue to receive events+
#  + events such as "the mouse has moved", "a key has been pressed" and so on
@event_queue = Rubygame::EventQueue.new

# Use new style events so that this software will work with Rubygame 3.0
@event_queue.enable_new_style_events

class Event
  attr_reader :type, :buttons, :x, :y, :pos, :timeout
  
  def initialize(ev)
    @type = ev.class.name.gsub("Rubygame::Events::", "").to_sym
    if ev.respond_to?("pos")
      @x = ev.pos[0]
      @y = ev.pos[1]
      @pos = ev.pos
    end
    if ev.respond_to?("button")
      @buttons = [ev.button]
    elsif (ev.respond_to?("buttons") and !ev.buttons.empty?)
      @buttons = ev.buttons
    end
    @timeout = Time.now.to_i
  end
  
end

@list = []

Thread.new do
  while true
    temp = nil
    @list.each do |e|
      if (Time.now.to_i - e.timeout >= 0)
        temp = e
        break
      end
    end
    if temp
      @list.delete(temp)
      puts temp.inspect
    end
    sleep 0.01
  end
end

# Wait for an event
while event = @event_queue.wait
  
  # Show the details of the event
  #p event.inspect
  @list << Event.new(event)
  
  # Stop this program if the user closes the window
  break if event.is_a? Rubygame::Events::QuitRequested
  
end
