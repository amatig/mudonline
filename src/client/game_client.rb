class IRCConnection
  
  # Ridefinizione del metodo loop della lib Ruby-IRC.
  def IRCConnection.main
    while (@@quit == 0)
      do_one_loop { |event| yield event }
      # tick per aggiorn. gragica e condizione per uscire
      gm = Game.instance
      unless gm.update
        gm.quit
        IRCConnection.quit
      end
    end
  end
  
end

class GameClient < IRC
  
  def initialize(nick, server, port, channels = [], options = {})
    super(nick, server, port, nil, options)
    # Callbakcs for the connection.
    IRCEvent.add_callback("endofmotd") do |event| 
      channels.each { |chan| add_channel(chan) }
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
    if event.channel != @nick
      ListEvents.instance.add_event(GameEvent.fromData("Irc", 
                                                       0, 
                                                       0, 
                                                       [0, 0], 
                                                       event.message, 
                                                       [], 
                                                       Time.now.to_i))
    end
  end
  
end
