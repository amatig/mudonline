class GameEvent
  attr_reader :type, :buttons, :x, :y, :pos, :timeout, :message
  
  def self.fromEvent(ev)
    type = ev.class.name.gsub("Rubygame::Events::", "").to_sym
    x = y = 0
    pos = [0, 0]
    if ev.respond_to?("pos")
      x = ev.pos[0]
      y = ev.pos[1]
      pos = ev.pos
    end
    message = ""
    buttons = []
    if ev.respond_to?("button")
      buttons = [ev.button]
    elsif (ev.respond_to?("buttons") and !ev.buttons.empty?)
      buttons = ev.buttons
    end
    if ev.respond_to?("key")
      buttons << ev.key
    end
    timeout = Time.now.to_i
    return new(type, x, y, pos, message, buttons, timeout)
  end
  
  def self.fromData(type, x, y, pos, message, buttons, timeout)
    return new(type, x, y, pos, message, buttons, timeout)
  end
  
  def initialize(type, x, y, pos, message, buttons, timeout)
    @type = type
    @x = x
    @y = y
    @pos = pos
    @message = message
    @buttons = buttons
    @timeout = timeout
  end
  
  private_class_method :new
  
end

class ListEvents
  include Singleton
  
  def initialize
    @list = []
    @mutex = Mutex.new
  end
  
  def have_event?
    return (check_event != nil)
  end
  
  def add_event(game_event)
    @mutex.synchronize do
      @list << game_event
    end
  end
  
  def check_event
    game_event = nil
    @mutex.synchronize do
      @list.each do |e|
        if (Time.now.to_i - e.timeout >= 0)
          game_event = e
          break
        end
      end
    end
    return game_event
  end
  
  def get_event
    game_event = check_event
    if game_event
      @mutex.synchronize do
        @list.delete(game_event)
      end
    end
    return game_event
  end
  
  private :check_event
  
end
