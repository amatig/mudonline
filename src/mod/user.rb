require "lib/database.rb"

# Classe per la gestione degli utenti.
# = Description
# Questa classe rappresenta l'entita' utente, una persona giocante.
#
# E' una classe con soli metodi statici per interfacciarsi direttamente ai dati nel database.
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

class User
  
  # Resetta i login degli utenti.
  def User.reset_login()
    Database.instance.update({
                               "logged" => 0, 
                               "mode" => "move", 
                               "target" => ""
                             }, 
                             "users", 
                             "logged=1")
  end
  
  # Stato del login utente.
  # @param [String] nick identificativo dell'utente.
  # @return [Integer] stato del login utente.
  def User.is_logged?(nick)
    data = Database.instance.get("logged", "users", "nick='#{nick}'")
    if data.empty?
      return -1
    else
      return Integer(data[0])
    end
  end
    
  # Effettua il login utente.
  # @param [String] nick identificativo dell'utente.
  def User.login(nick)
    Database.instance.update({
                               "logged" => 1, 
                               "mode" => "move", 
                               "target" => "",
                               "timestamp" => Time.now.to_i
                             },
                             "users", 
                             "nick='#{nick}'")
  end
  
  # Effettua il logout utente.
  # @param [String] nick identificativo dell'utente.
  def User.logout(nick)
    Database.instance.update({
                               "logged" => 0,
                               "mode" => "move", 
                               "target" => ""
                             }, 
                             "users", 
                             "nick='#{nick}'")
  end
  
  # Cambia la modalita' di interazione dell'utente.
  # @param [String] nick identificativo dell'utente.
  # @param [String] mode modalita' di interazione dell'utente.
  # @param [String] target riferimento dell'interazione.
  def User.set_mode(nick, mode, target)
    Database.instance.update({"mode" => mode, "target" => target}, 
                             "users", 
                             "nick='#{nick}'")
  end
  
  # Modalita' di interazione dell'utente.
  # @param [String] nick identificativo dell'utente.
  # @return [String] stato della modalita' di interazione dell'utente.
  def User.get_mode(nick)
    data = Database.instance.get("mode", "users", "nick='#{nick}'")
    return data[0]
  end
    
  # Target della modalita' di interazione.
  # @param [String] nick identificativo dell'utente.
  # @return [String] riferimento della modalita' di interazione.
  def User.get_target(nick)
    data = Database.instance.get("target", "users", "nick='#{nick}'")
    return data[0]
  end
  
  # Aggiorna il timestamp dell'utente, questa variabile tiene traccia
  # del tempo dell'ultimo messaggio inviato dall'utente al fine
  # sloggarlo per inattivita'.
  # @param [String] nick identificativo dell'utente.
  def User.update_timestamp(nick)
    Database.instance.update({"timestamp" => Time.now.to_i}, 
                             "users", 
                             "nick='#{nick}'")
  end
  
  # Timestamp dell'utente, il tempo dell'ultimo messaggio inviato.
  # @param [String] nick identificativo dell'utente.
  # @return [Integer] timestamp dell'ultimo messaggio inviato dall'utente.
  def User.get_timestamp(nick)
    data = Database.instance.get("timestamp", "users", "nick='#{nick}'")
    return Integer(data[0])
  end
  
  # Dettagli dell'utente.
  # @param [String] nick identificativo dell'utente.
  # @return [Array<Integer, String>] insieme di informazioni sull'utente.
  def User.get_details(nick)
    data = Database.instance.get("*", "users", "nick='#{nick}'")
    return [Integer(data[3]), data[4], Integer(data[2])]
  end
  
  # Modifica l'indice del posto in cui si trova l'utente.
  # @param [String] nick identificativo dell'utente.
  # @param [Integer] place_id indice del nuovo posto.
  def User.set_place(nick, place_id)
    Database.instance.update({"place_id" => Integer(place_id)}, 
                             "attributes", 
                             "user_nick='#{nick}'")
  end
  
  # Indice del posto in cui si trova l'utente.
  # @param [String] nick identificativo dell'utente.
  # @return [Integer] indice del posto in cui si trova l'utente.
  def User.get_place(nick)
    data = Database.instance.get("place_id", "attributes", "user_nick='#{nick}'")
    return Integer(data[0])
  end
  
  # Setta lo stato dell'utente come 'in piedi'. Se l'utente non era tale 
  # ritorna true, se era gia' 'in piedi' ritorna false.
  # @param [String] nick identificativo dell'utente.
  # @return [Boolean] esito dell'operazione.
  def User.set_up(nick)
    data = Database.instance.get("stand_up", 
                                 "attributes", 
                                 "user_nick='#{nick}'")
    if (data[0] == "1")
      return false
    else
      Database.instance.update({"stand_up" => 1}, 
                               "attributes", 
                               "user_nick='#{nick}'")
      return true
    end
  end
  
  # Setta lo stato dell'utente come 'per terra'. Se l'utente non era tale 
  # ritorna true, se era gia' 'per terra' ritorna false.
  # @param [String] nick identificativo dell'utente.
  # @return [Boolean] esito dell'operazione.
  def User.set_down(nick)
    data = Database.instance.get("stand_up", 
                                 "attributes", 
                                 "user_nick='#{nick}'")
    if (data[0] == "0")
      return false
    else
      Database.instance.update({"stand_up" => 0}, 
                               "attributes", 
                               "user_nick='#{nick}'")
      return true
    end
  end
  
  # Stato dell'utente, se e' 'in piedi' o no.
  # @param [String] nick identificativo dell'utente.
  # @return [Boolean] stato 'in piedi' dell'utente.
  def User.stand_up?(nick)
    data = Database.instance.get("stand_up", 
                                 "attributes", 
                                 "user_nick='#{nick}'")
    return (data[0] == "1")
  end
    
end
