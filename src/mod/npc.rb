require "rexml/document"
require "lib/database.rb"
require "lib/utils.rb"

# Classe per la gestione degli NPC (Non-Player Character).
# = Description
# Questa classe rappresenta l'entita' npc, personaggio non giocante del mud.
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

class Npc
  include Utils
  
  # Identificativo dell'npc.
  # @return [String] identificativo dell'npc.
  attr_reader :name
  # Descrizione dell'npc.
  # @return [String] descrizione dell'npc.
  attr_reader :descr
  # Indice del posto in cui e' l'npc.
  # @return [Integer] indice del posto in cui e' l'npc.
  attr_reader :place
  
  # Una nuova istanza di Npc.
  def initialize(name)
    @db = Database.instance # singleton
    
    file = File.new("data/npcs/#{name}.xml")
    doc = REXML::Document.new(file)
    root = doc.elements["npc"]
    @name = name.capitalize
    @descr = root.elements["descr"].text
    @place = Integer(root.elements["place"].text)
    @memory = Integer(root.elements["memory"].text)
    @availability = Integer(root.elements["availability"].text)
    @goodness = Integer(root.elements["goodness"].text)
    @max_type = Integer(root.elements["max_type"].text)
    @likes = {}
    root.elements["likes"].each_element do |val|
      @likes[val.name] = val.text
    end
    @hates = {}
    root.elements["hates"].each_element do |val|
      @hates[val.name] = val.text
    end
    file.close
    
    # caricamento dei messaggi dell'npc
    localization("data/npcs/#{name}.xml", "npc")
  end
  
  # Logica dell'npc, dell'interazione con l'utente.
  # @param [String] nick identificativo dell'utente.
  # @param [String] msg messaggio utente.
  # @return [Array<Integer, String>] codice tipo e messaggio finale dell'npc.
  def parse(nick, msg)
    regex =  "(da\\w?|ha\\w?|sa\\w?|conosc\\w{1,3}|sapete|d\\w[rct]\\w{1,2}|qualche|alcun\\w)\\s"
    regex += "(particolar\\w|niente|cosa|qualcosa|info\\w*|notizi\\w|dettagl\\w{1,2})\\s"
    regex += "(su\\w{0,3}|d\\w{0,4}|riguardo)\\s([A-z\\ ]+)"
    
    case msg
    when /^_start_18278374937_$/
      return reply_start(nick)
    when /^(ciao|salve)/i
      return reply(nick, "welcome")
    when /^(arrivederci|addio|a\spresto|alla\sprossima|vado)/i
      return reply(nick, "goodbye")
    when /#{regex}/i
      return reply_info(nick, "quest_info", $4)
    when /dove.+(e'|sono|sta\w{0,3}|essere|trova\w{0,2})\s([A-z\\ ]+)\?/i
      return reply_info(nick, "quest_find", $2)
    else
      if msg.index("?") != nil
        return reply(nick, "err_qst")
      else
        return reply(nick, "err_aff")
      end
    end
  end
  
  # Comincia il dialogo con l'utente se e' disponibile.
  # @see Npc#is_free?
  # @param [String] nick identificativo dell'utente.
  # @param [String] type tipo di messaggio.
  # @return [Array<Integer, String>] codice tipo e messaggio finale dell'npc.
  def reply_start(nick)
    if not is_free?(nick) # npc non disponibile
      return [0, bold(@name) + ": " + _("busy")]
    else
      return [1, bold(@name) + ": " + _("welcome")]
    end
  end
  
  # Rende variabile il messaggio dell'npc simulando un dialogo.
  # @see Npc#level_crave
  # @see Npc#cache_crave
  # @param [String] nick identificativo dell'utente.
  # @param [String] type tipo di messaggio.
  # @return [Array<Integer, String>] codice tipo e messaggio finale dell'npc.
  def reply(nick, type)
    r = 1
    msg = ""
    if type == "goodbye"
      r = 0
      msg = _(type)
    else
      diff = level_crave(nick, type) - @max_type
      if diff >= 0
        esito = "crave_#{type}"
        msg = __(esito, diff)
        # @_counts e' presente nel modulo utils incluso
        cache_crave(nick, type) if (diff < @_counts[esito])
      else
        msg = _(type)
        cache_crave(nick, type)
      end
    end
    return [r, bold(@name) + ": " + msg]
  end
  
  # Ritorna le informazioni che ha un npc rispetto ad un argomento
  # richiesto dall'utente.
  # @see Npc#level_crave
  # @see Npc#cache_crave
  # @param [String] nick identificativo dell'utente.
  # @param [String] type tipo di messaggio.
  # @param [String] target oggetto di cui l'utente vuole informazioni.
  # @return [Array<Integer, String>] codice tipo e messaggio finale dell'npc.
  def reply_info(nick, type, target)
    t = type.split("_")
    msg = ""
    diff = level_crave(nick, t[0], target) - @max_type
    # aggingere in qualche modo la condizione dell'npc nella scelta
    if diff >= 0
      esito = "crave_#{t[0]}"
      msg = __(esito, diff)
      # @_counts e' presente nel modulo utils incluso
      cache_crave(nick, t[0], target) if (diff < @_counts[esito])
    else
      puts t[1]
      pattern = clean(target).gsub(" ", "%")
      info = @db.get("data",
                     "npc_info",
                     "type='#{t[1]}' and pattern like '%#{pattern}%'")
      msg = (info.empty?) ? _("no_#{t[1]}") : info[0]
      cache_crave(nick, t[0], target)
    end
    return [2, bold(@name) + ": " + msg]
  end
  
  # Numero di richieste in cache dell'npc di un particolare tipo.
  # @param [String] nick identificativo dell'utente.
  # @param [String] type tipo di messaggio.
  # @param [String] target oggetto di cui l'utente vuole informazioni.
  # @return [Integer] numero di richeste cachate.
  def level_crave(nick, type, target = "")
    @db.delete("npc_caches", "#{Time.now.to_i}-timestamp>#{@memory}")
    c = @db.read("type,target",
                 "npc_caches",
                 "user_nick='#{nick}' and npc_name='#{@name}' and type='#{type}' and target='#{target}'")
    return c.length
  end
  
  # Controlla la cache delle richieste in maniera che si possa sapere se
  # un particolare tipo di argomento e' insistente da parte di un utente.
  # Ne ottiene dei valori che accoppiati con le le logiche dell'npc servono 
  # a decidere come rispondere all'utente.
  # @param [String] nick identificativo dell'utente.
  # @param [String] type tipo di messaggio.
  # @param [String] target oggetto di cui l'utente vuole informazioni.
  # @return [Array<Boolean>] valori di decisione dell'npc.
  def check_crave(nick, type, target = "")
    @db.delete("npc_caches", "#{Time.now.to_i}-timestamp>#{@memory}")
    
    if type != "quest"
      # cache per tipo
      c2 = @db.read("type,target",
                    "npc_caches",
                    "user_nick='#{nick}' and npc_name='#{@name}' and type='#{type}'")
      n = @max_type - c2.length + 1
      n = 1 if n <= 0 # se per errori imprevisti la cache supera il max
      # non permette + del max per tipo, dando casualita'
      return [false, false] if rand(n) <= 0
    end
    
    # cache totale
    c1 = @db.read("type,target",
                  "npc_caches",
                  "user_nick='#{nick}' and npc_name='#{@name}' and type='quest'")
    n = @availability - c1.length + 1
    n = 1 if n <= 0 # se per errori imprevisti la cache supera il max
    disponibilita = rand(n) > 0 # rende + casuale la risposta
    
    pl_wh = @db.read("weather", "places", "id=#{@place}")[0]
    i = @goodness
    now = mud_time.hour
    ls = le = hs = he = 0
    begin
      ls, le = @likes["timerange"].split("-")
      i += Integer(@likes["value"]) if (Integer(ls) <= now and now < Integer(le))
    rescue
    end
    begin
      hs, he = @hates["timerange"].split("-")
      i -= Integer(@hates["value"]) if (Integer(hs) <= now and now < Integer(he))
    rescue
    end
    if @likes.has_key?("weather")
      i += Integer(@likes["value"]) if Integer(@likes["weather"]) == pl_wh
    end
    if @hates.has_key?("weather")
      i -= Integer(@hates["value"]) if Integer(@hates["weather"]) == pl_wh
    end
    
    bonta = false
    if i > 1
      bonta = rand(i) <= Integer((i - 1) / 2)
    end
    # puts "#{i} #{Integer((i - 1) / 2)}"
    
    return [disponibilita, bonta]
  end
  
  # Crea una cache di una richiesta.
  # @param [String] nick identificativo dell'utente.
  # @param [String] type tipo di messaggio.
  # @param [String] target oggetto di cui l'utente vuole informazioni.
  def cache_crave(nick, type, target = "")
    @db.insert({
                 "user_nick" => nick,
                 "npc_name" => @name,
                 "type" => type,
                 "target" => target,
                 "timestamp" => Time.now.to_i
               }, 
               "npc_caches")
  end
  
  # Tramite i valori dei dati in possesso dell'npc (valori cache),
  # stabilisce se un npc e' disponibile per il dialogo.
  # @param [String] nick identificativo dell'utente.
  # @return [Boolean] disponibilita' dell'npc.  
  def is_free?(nick)
    #d, b = check_crave(nick, type)
    return true
  end
  
  # Identificativo dell'npc.
  # @return [String] identificativo dell'npc.
  def to_s()
    return @name
  end
  
  private :reply_start, :reply, :reply_info, :check_crave, :level_crave, :cache_crave, :is_free?
end
