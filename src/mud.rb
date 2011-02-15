#!/usr/bin/ruby
require "rubygems"
require "IRC"
require "lib/database.rb"
require "core.rb"

# Classe principale del mud che utilizza Ruby-IRC, un framework di connessione e comunicazione con server Irc.
# = Description
# Questa classe si occupa di distinguere ed eseguire/rispondere ai comandi degli utenti, e' stata scissa 
# in due con la classe Core che elabora realmente i dati di un comando e ritorna il messaggio generato per 
# l'invio all'utente attraverso il server Irc.
#
# Nello script di main viene anche inizializzato il singleton Database per la connessione ai dati su server Postgres.
#
# = License
# Nemesis - IRC Mud Multiplayer Online totalmente italiano
#
# Copyright (C) 2010 Giovanni Amati
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
# = Authors
# Giovanni Amati

class Mud < IRC
  
  # Una nuova istanza di Mud.
  #
  # Istanzia inoltre la classe Core che ha al suo interno
  # l'elaborazione dati dei comandi e la messaggistica di ritorno del mud.
  # @param [String] nick identificativo del bot mud.
  # @param [String] server indirizzo del server irc.
  # @param [Integer] port porta del server irc.
  # @param [Array<String>] channels lista dei canali in cui inserire il bot.
  # @param [Hash] options hash di opzioni per la connessione irc.
  # @option options [Boolean] :use_ssl per usare ssl nella connessione.
  def initialize(nick, server, port, channels = [], options = {})
    super(nick, server, port, nil, options)
    # Callbakcs for the connection.
    IRCEvent.add_callback("endofmotd") do |event| 
      channels.each { |chan| add_channel(chan) }
      puts "Mud is running..."
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
    @core = Core.new # instanza di Core per i messaggi di ritorno
  end
  
  # Smembra e smista i messaggi utente per messaggi di canale o privati.
  # @param [Event] event oggetto complesso contenete il messaggio utente.
  def parse(event)
    # puts Thread.current
    if event.channel == @nick
      delivery_priv(event.from, event.message)
    else
      delivery_chan(event.channel, event.from, event.message)
    end
  end
  
  # Gestisce i messaggi di canale.
  # @param [String] channel identificativo del canale.
  # @param [String] nick identificativo dell'utente.
  # @param [String] msg messaggio utente.
  def delivery_chan(channel, nick, msg)
    send_message(channel, @core.info(nick))
  end
  
  # Gestisce i messaggi privati.
  # @param [String] nick identificativo dell'utente.
  # @param [String] msg messaggio utente.
  def delivery_priv(nick, msg)
    login, mode, timestamp = @core.get_user_details(nick)
    case login
    when -1
      send_message(nick, @core.user_not_exist)
    when 0
      greeting = (msg =~ /^(ciao|salve)$/i) ? $1 : nil
      send_message(nick, @core.login(nick, greeting))
    when 1
      @core.update_user_timestamp(nick) # segnala attivita' utente
      # modalita' di interazione
      case mode
      when "move"
        mode_navigation(nick, msg)
      when "dialog"
        mode_dialog(nick, msg)
      end
    end
  end
  
  # Gestisce la modalita' di interazione 'navigazione'.
  # @param [String] nick identificativo dell'utente.
  # @param [String] msg messaggio utente.
  def mode_navigation(nick, msg)
    case msg
    when /mi\s(alzo|sveglio)/i
      send_message(nick, @core.cmd_up(nick))
    when /mi\s(siedo|addormento|sdraio|riposo|stendo|distendo)/i
      send_message(nick, @core.cmd_down(nick))
    when /dove.+(sono|siamo|finit\w|trov\w{1,4})\?/i
      send_message(nick, @core.cmd_place(nick))
    when /dove.+(recar\w{1,2}|andar\w{1,4}|procedere|diriger\w{1,2})\?/i
      send_message(nick, @core.cmd_nearby_places(nick))
    when /(andiamo|va\w{0,2})\s(ne|a)\w{0,3}\s([A-z0-9\ ]+)/i
      send_message(nick, @core.cmd_move(nick, $3))
    when /chi.+(qu\w|zona|luogo|paraggi)\?/i
      send_message(nick, @core.cmd_users_in_zone(nick))
    when /(esamin\w|guard\w|osserv\w|scrut\w|analizz\w)\s([A-z0-9\ ]+)/i
      send_message(nick, @core.cmd_look(nick, $2))
    when /(parl\w|dialog\w)\s(a|con)\s([A-z0-9\ ]+)/i
      send_message(nick, @core.cmd_speak(nick, $3))
    when /(ciao|salve)\s([A-z0-9\ ]+)/i
      send_message(nick, @core.cmd_speak(nick, $2))
    when /^(fine|stop|esci|exit|quit|basta)$/i
      send_message(nick, @core.logout(nick))
    else
      send_message(nick, @core.cmd_not_found)
    end
  end
  
  # Gestisce la modalita' di interazione 'dialogo'.
  # @param [String] nick identificativo dell'utente.
  # @param [String] msg messaggio utente.
  def mode_dialog(nick, msg)
    send_message(nick, @core.dispatch_to_npc(nick, msg))
  end
  
  private :delivery_priv, :delivery_chan, :mode_navigation, :mode_dialog
end


# MAIN SCRIPT

if __FILE__ == $0
  begin
    Database.instance.connect("127.0.0.1", 5432, "mud_db", "postgres")
    Mud.new("GameMaster", "127.0.0.1", 6667, ["\#Hall"]).connect
  rescue Interrupt
  rescue Exception => e
    puts "MainLoop: " + e.message
    print e.backtrace.join("\n")
    #retry # ritenta dal begin
  ensure
    Database.instance.close
  end
end
