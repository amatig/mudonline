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
@objects = []

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

class Meanie
  # Turn this object into a sprite
  include Rubygame::Sprites::Sprite
  
  def initialize
    # Invoking the base class constructor is important and yet easy to forget:
    super()
    
    # @image and @rect are expected by the Rubygame sprite code
    @image = Rubygame::Surface.load "prova.png"
    @rect  = @image.make_rect
    
    @angle = 2*Math::PI * rand
  end
  
  # Animate this object.  "seconds_passed" contains the number of ( real-world)
  # seconds that have passed since the last time this object was updated and is
  # therefore useful for working out how far the object should move ( which
  # should be independent of the frame rate)
  def update seconds_passed
    
    # This example makes the objects orbit around the center of the screen.
    # The objects make one orbit every 4 seconds
    @angle = ( @angle + 2*Math::PI / 4 * seconds_passed) % ( 2*Math::PI)
    
    @rect.topleft = [ 320 + 100 * Math.sin(@angle),
                      240 - 100 * Math.cos(@angle)]
  end
  
  def draw on_surface
    @image.blit on_surface, @rect
  end
  
end


@clock = Rubygame::Clock.new
@clock.target_framerate = 30
@clock.enable_tick_events

@sprites = Rubygame::Sprites::Group.new
Rubygame::Sprites::UpdateGroup.extend_object @sprites
3.times { @sprites << Meanie.new }

@background = Rubygame::Surface.load "background.jpg"
@background.blit @screen, [0, 0]

should_run = true
while should_run do
  
  seconds_passed = @clock.tick().seconds
  
  @event_queue.each do |event|
    case event
    when Rubygame::Events::QuitRequested, Rubygame::Events::KeyReleased
      should_run = false
    end
    @list << Event.new(event)
  end
  
  # "undraw" all of the sprites by drawing the background image at their
  # current location ( before their location has been changed by the animation)
  @sprites.undraw @screen, @background
  
  # Give all of the sprites an opportunity to move themselves to a new location
  @sprites.update seconds_passed
  
  # Draw all of the sprites
  @sprites.draw @screen
  
  @screen.flip
  
end
