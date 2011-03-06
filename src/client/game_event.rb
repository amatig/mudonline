class GameEvent
  attr_reader :type, :x, :y, :pos, :message, :buttons, :timeout
  
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
      buttons << ev.button
    end
    if (ev.respond_to?("buttons") and !ev.buttons.empty?)
      buttons.concat(ev.buttons)
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
    @list = [] # lista effettiva di mie eventi
    @mutex = Mutex.new
    @next_event = nil # per ottimizzare
  end
  
  def have_event?
    @next_event = check_event
    return (@next_event != nil)
  end
  
  def add_event(game_event)
    @mutex.synchronize do
      @list << game_event
    end
  end
  
  def check_event
    @mutex.synchronize do
      @list.each do |event|
        if (Time.now.to_i - event.timeout >= 0)
          return event
        end
      end
    end
    return nil
  end
  
  def get_event
    event = (@next_event) ? @next_event : check_event
    @next_event = nil
    if event
      @mutex.synchronize do
        @list.delete(event)
      end
    end
    return event
  end
  
  private :check_event
  
end
