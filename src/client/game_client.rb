class IRCConnection
  
  def IRCConnection.do_one_loop
    read_sockets = select(@@readsockets, nil, nil, 0.03) # cambiati i secondi di sleep
    if !read_sockets.nil?
      read_sockets[0].each {|sock|
        if sock.eof? && sock == @@socket
          remove_IO_socket(sock)
          sleep 10
          handle_connection(@server, @port, @nick, @realname)
        else
          yield @@events[sock.object_id.to_i].call(sock)
        end
      }
    end
    if @@output_buffer.length > 0
      timer = Time.now.to_f
      if (timer > @@last_send + @@message_delay) 
        message = @@output_buffer.shift()
        if !message.nil?
          IRCConnection.send_to_server(message)
          @@last_send = timer
        end
      end
    end
    IRCConnection.update_game
  end
  
  def IRCConnection.update_game
    gm = Game.instance
    unless gm.update
      gm.quit
      IRCConnection.quit
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
