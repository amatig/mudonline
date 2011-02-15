require "thread"
require "lib/database.rb"

# Classe per la gestione dei posti.
# = Description
# Questa classe rappresenta l'entita' posto, un luogo del mondo del mud.
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

class Place
  # Indice del posto.
  # @return [Integer] indice del posto.
  attr_reader :id
  # Identificativo del posto.
  # @return [String] identificativo del posto.
  attr_reader :name
  # Descrizione del posto.
  # @return [String] descrizione del posto.
  attr_reader :descr
  # Rappresenta se un posto e' maschile/femminile singolare/plurale,
  # serve per poterne identificare l'articolo.
  # @return [Integer] attributo per identificare l'articolo.
  attr_reader :attrs
  # Lista dei posti adiacenti.
  # @return [Array<Place>] lista dei posti adiacenti.
  attr_reader :nearby_places
  
  # Una nuova istanza di Place.
  # @param [Array<String>] data contiene alcune informazioni sul posto.
  def initialize(data)
    @db = Database.instance # singleton
    @id = Integer(data[0])
    
    file = File.new("data/places/#{data[1]}.xml")
    doc = REXML::Document.new(file)
    root = doc.elements["place"]
    @name = root.elements["name"].text
    @descr = root.elements["descr"].text
    @attrs = Integer(root.elements["attrs"].text)
    file.close
        
    @nearby_places = []
    @people_here = []
    
    @init_np = false # fa fare l'init_nearby_places una sola volta
    
    @mutex = Mutex.new
  end
  
  # Inizializza (aggiunge) a questo luogo le istanze dei posti vicini,
  # un flag si assicurara che l'operazione possa essere fatta una sola volta.
  # @param [Array<Place>] nearby_places lista delle istanze dei posti adiacenti.
  def init_nearby_places(nearby_places)
    unless @init_np
      @nearby_places = nearby_places
      @init_np = true
    end
  end
  
  # Condizione metereologica del posto.
  # @return [Integer] rappresenta la condizione meteo della zona.
  def get_weather()
    data = @db.get("weather", "places", "id='#{@id}'")
    return Integer(data[0])
  end
  
  # Rimuove un utente o npc dalla lista delle persone in questo posto.
  # @param [Npc, String] p identificativo di un utente o instanza di Npc.
  def remove_people(p)
    @mutex.synchronize { @people_here.delete(p) if @people_here.include?(p) }
  end
  
  # Aggiunge un utente o npc dalla lista delle persone in questo posto.
  # @param [Npc, String] p identificativo di un utente o instanza di Npc.
  def add_people(p)
    @mutex.synchronize { @people_here << p unless @people_here.include?(p) }
  end
  
  # Lista di tutti le persone presenti nel posto, sia utenti che npc.
  # @return [Array<Npc, String>] lista degli utenti e instanze di Npc.
  def get_peoples()
    @mutex.synchronize { return @people_here }
  end
  
  # Identificativo del posto.
  # @return [String] identificativo del posto.
  def to_s()
    return @name
  end
  
end
