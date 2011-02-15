require "thread"
require "logger"
require "lib/database.rb"
require "lib/utils.rb"
require "mod/user.rb"
require "mod/npc.rb"
require "mod/place.rb"

# Classe dei comandi/messaggi del mud.
# = Description
# Questa classe implementa l'elaborazione dei dati dei comandi utente e genera i messaggi di ritorno alla classe Mud che li invia al server Irc.
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

class Core
  include Utils
  
  # Una nuova istanza di Core.
  def initialize()
    @log = Logger.new("log/core.log")
    @db = Database.instance # singleton
    
    @place_list = {}
    @npc_list = {}
    
    # caricamento dei messaggi del mud
    localization("data/mud.xml", "mud")
    # caricamento dati mondo
    init_data
  end
  
  # Inizializza tutti gli elementi del gioco.
  def init_data()
    User.reset_login
    
    @place_list = {}
    places = @db.read("*", "places")
    places.each { |p| @place_list[Integer(p[0])] = Place.new(p) }
    places.each do |p|
      list_np = @db.read("places.id", 
                         "links,places", 
                         "place_id=#{p[0]} and places.id=nearby_place_id")
      temp = list_np.map { |near| @place_list[Integer(near[0])] }
      @place_list[Integer(p[0])].init_nearby_places(temp)
    end
    
    @npc_list = {}
    npcs = @db.read("name", "npcs")
    npcs.each do |n|
      temp = Npc.new(n[0])
      @npc_list[temp.name] = temp
      @place_list[temp.place].add_people(temp)
    end
  end
  
  # Test comunicazione in canale.
  # @param [String] nick identificativo dell'utente.
  # @return [String] messaggio del mud.
  def info(nick)
    return _("test") % nick
  end
  
  # Messaggio random per un comando sconosciuto.
  # @return [String] messaggio del mud.
  def cmd_not_found()
    return _("cnf")
  end
  
  # Messaggio di utente non registrato dal mud.
  # @return [String] messaggio del mud.
  def user_not_exist()
    return _("no_reg")
  end
  
  # Effettua il login di un utente dal sistema.
  # @param [String] nick identificativo dell'utente.
  # @param [String] greeting parola usata dall'utente per salutare.
  # @return [String] messaggio del mud.
  def login(nick, greeting = nil)
    if greeting == nil
      return _("r_welcome")
    else
      User.login(nick)
      @place_list[User.get_place(nick)].add_people(nick)
      return _("welcome") % [bold(nick), cmd_place(nick)]
    end
  end
  
  # Effettua il logout di un utente dal sistema.
  # @param [String] nick identificativo dell'utente.
  # @return [String] messaggio del mud.
  def logout(nick)
    User.logout(nick)
    @place_list[User.get_place(nick)].remove_people(nick)
    return _("logout") % bold(nick)
  end
  
  # Aggiorna il timestamp dell'utente, che indica il momento dell'ultimo
  # messaggio inviato.
  # @param [String] nick identificativo dell'utente.
  def update_user_timestamp(nick)
    User.update_timestamp(nick)
  end
  
  # Dettagli dell'utente.
  # @param [String] nick identificativo dell'utente.
  # @return [Array<Integer, String>] insieme di informazioni sull'utente.
  def get_user_details(nick)
    return User.get_details(nick)
  end
  
  # Muove l'utente in un posto vicino (collegato) a quello attuale.
  # @param [String] nick identificativo dell'utente.
  # @param [String] place_name nome del luogo in cui ci si vuole spostare.
  # @return [String] messaggio del mud.
  def cmd_move(nick, place_name)
    unless User.stand_up?(nick)
      return _("uaresit")
    else
      old_p = @place_list[User.get_place(nick)]
      old_p.nearby_places.each do |p|
        if p.name =~ /#{place_name.strip}/i
          old_p.remove_people(nick)
          User.set_place(nick, p.id) # cambio di place_id
          p.add_people(nick)
          temp = pa_in(a_d(p.attrs, p.name)) + bold(p.name)
          return _("new_place") % [temp, p.descr]
        end
      end
      return _("no_place") % place_name
    end
  end
  
  # Descrizione del posto in cui e' l'utente.
  # @param [String] nick identificativo dell'utente.
  # @return [String] messaggio del mud.
  def cmd_place(nick)
    p = @place_list[User.get_place(nick)]
    temp = pa_in(a_d(p.attrs, p.name)) + bold(p.name)
    return _("place") % [temp, p.descr]
  end
  
  # Elenca i posti vicini in cui si puo andare.
  # @param [String] nick identificativo dell'utente.
  # @return [String] messaggio del mud.
  def cmd_nearby_places(nick)
    l = @place_list[User.get_place(nick)].nearby_places
    temp = l.map { |p| pa_di(a_d(p.attrs, p.name)) + bold(p.name) }
    return _("near_places") % conc(temp)
  end
  
  # Fa alzare l'utente.
  # @param [String] nick identificativo dell'utente.
  # @return [String] messaggio del mud.
  def cmd_up(nick)
    return _("up_#{User.set_up(nick)}")
  end
  
  # Fa abbassare l'utente.
  # @param [String] nick identificativo dell'utente.
  # @return [String] messaggio del mud.
  def cmd_down(nick)
    return _("down_#{User.set_down(nick)}")
  end
  
  # Descrizione di un npc, oggetto o altro.
  # @param [String] nick identificativo dell'utente.
  # @param [String] name nome dell'utente/npc/oggetto da esaminare.
  # @return [String] messaggio del mud.
  def cmd_look(nick, name)
    @place_list[User.get_place(nick)].get_peoples.each do |p|
      if p.class == Npc
        return _("desc_npc") % [p.name, p.descr] if p.name =~ /^#{name.strip}$/i
      else
        return _("desc_people") if p =~ /^#{name.strip}$/i
      end
    end
    # se nn e' un npc controlla gli oggetti con quel nome ecc
    # da fare ...
    return _("nothing") % name
  end
  
  # Elenca gli npc ed utenti nella zona.
  # @param [String] nick identificativo dell'utente.
  # @return [String] messaggio del mud.
  def cmd_users_in_zone(nick)
    u = []
    @place_list[User.get_place(nick)].get_peoples.each do |p|
      unless p.class == Npc
        u << bold(p) if (p != nick)
      else
        u << italic(p.name)
      end
    end
    if u.empty?
      c = _("nobody") + ","
      u = [_("onlyu")]
    else
      c = _((u.length > 1) ? "ci_sono" : "c_e")
    end
    return _("users_zone") % [c, conc(u)]
  end
  
  # Entra in modalita' interazione 'dialogo' con un npc.
  # @param [String] nick identificativo dell'utente.
  # @param [String] name identificativo dell'npc.
  # @return [String] messaggio dell'npc o del mud.
  def cmd_speak(nick, name)
    npc = @npc_list[name.strip.capitalize]
    if npc and npc.place == User.get_place(nick)
      User.set_mode(nick, "dialog", npc.name)
      return dispatch_to_npc(nick, "_start_18278374937_")
    else
      return _("nothing_npc") % name
    end
  end
  
  # Demanda all'npc l'interazione vera e propria con l'utente.
  # @param [String] nick identificativo dell'utente.
  # @param [String] msg messaggio utente.
  # @return [String] messaggio npc.
  def dispatch_to_npc(nick, msg)
    r = @npc_list[User.get_target(nick)].parse(nick, msg)
    User.set_mode(nick, "move", "") if r[0] == 0 # goodbye?
    return r[1]
  end
  
  private :init_data
end
