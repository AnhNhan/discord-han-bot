require 'discordrb'
require 'yaml'
require 'net/http'
require 'uri'
require 'json'
require 'levenshtein'

###########################################################
#### MODULES
###########################################################

module GeneralAnnouncer
  extend Discordrb::EventContainer

  member_join do |event|
    event.server.general_channel.send_message "#{event.user.mention} joined! Please welcome him!"
  end

  member_leave do |event|
    event.server.general_channel.send_message "#{event.user.mention} left the server. He better had a reason to."
  end
end

module FutileResponses
  extend Discordrb::EventContainer

  def self.pick_random(event)
    responses = [
      "@@@@, it is meaningless to converse with a soulless machine.",
      "@@@@, there is no hope in talk with me.",
      "I impersonate silence. I see no purpose in your action, @@@@."
    ]
    selected_response = responses.sample
    selected_response["@@@@"] = event.user.mention
    return selected_response
  end

  mention do |event|
    event.respond self.pick_random(event)
  end

  pm do |event|
    event.respond self.pick_random(event)
  end
end

module GreetTheCommander
  extend Discordrb::EventContainer

  weather_uri_ansbach = URI("http://api.openweathermap.org/data/2.5/weather?id=2955936&units=metric&appid=689642cefcdae7cb38b5e6070034f31e")

  presence do |event|
    if "AnhNhan".eql?(event.user.name) && :online.eql?(event.status)
      weather_data = JSON.parse(Net::HTTP.get(weather_uri_ansbach))
      current_temp = weather_data["main"]["temp"]
      event.server.general_channel.send_message "#{event.user.mention}\nWelcome back, commander!\nCurrent temperature is #{current_temp}°C.\nReactor online.\nSensors online.\nWeapons online.\nAll systems nominal."
    end
  end
end

module AnnouncePossibleGames
  extend Discordrb::EventContainer

  presence do |event|
    if event.server
      online_users = event.server.users.select{ |u| u.status.eql?(:online) }
      if online_users.length == 6
        online_user_names = online_users.map(&:name).join ", "
        event.server.general_channel.send_message "There are a total of six people online. Perfect for a Company of Heroes match on The Sheldt!\n(#{online_user_names})"
      end
    end
  end
end

module Pokedex
  extend Discordrb::EventContainer

  @@pokedex = JSON.parse(File.read("pokemon-list.json"))
  @@name_search_indexes = [ "name_de", "name_en", "name_fr", "name_jp", "name_jpr", "name_kr", "name_krr" ]

  def self.search_pokemon(query)
    if query =~ /^\d+$/
      # search by id
      #
      # strip all leading zeros and re-pad them later again
      # this is necessary since the user might input too many zeroes
      query = query.gsub /^0+/, ""
      query = query.rjust(3, "0")
      return @@pokedex.find{ |entry| query.eql? entry["id"] }
    else
      # search by name
      # slighty fuzzy search, not too fast, not too precise, pokemon with similar name may be mistaken
      query = query.downcase.gsub /\s/, ""
      #puts "current query: #{query}"
      return nil if !query

      @@pokedex.find do |entry|
        entryname = entry["name_de"]
        #puts "at entry: #{entryname}"
        @@name_search_indexes.find do |index|
          current_hayneedle = entry[index].downcase.gsub /\s/, ""
          next if !current_hayneedle
          distance_target = current_hayneedle.length / 4.0
          distance = Levenshtein.distance query, current_hayneedle
          #puts "#{current_hayneedle}: #{distance} -- #{distance_target}"
          distance < distance_target
        end
      end
    end
  end

  message(start_with: /\#pokedex\s+[^\s]/i) do |event|
    query_string = event.message.content.scan(/\#pokedex\s+(.*?)\s*$/i)[0][0]
    #event.send_message query_string
    search = self.search_pokemon(query_string)
    if search
      imageinfo_api_uri = URI("http://www.pokewiki.de/api.php?action=query&format=json&prop=imageinfo&titles=Datei:Sugimori_709.png&iiprop=url")
      imageinfo = JSON.parse(Net::HTTP.get(imageinfo_api_uri))
      imageurl = imageinfo["query"]["pages"].values[0]["imageinfo"][0]["url"]

      entry = "**Pokédex-Eintrag *\#" + search["id"] + "***\n"
      entry += "**" + search["name_de"] + "** (" + [search["name_en"], search["name_jpr"]].join(", ") + ")\n"
      entry += "Typ: _" + search["type"].join("_, _") + "_\n"
      entry += imageurl + "\n"
      entry += "http://www.pokewiki.de/" + search["name_de"] + "\n"
      event.send_message entry
    else
      event.send_message "#{event.user.mention} '#{query_string}' could not be found in the Pokédex."
    end
  end
end

###########################################################
#### MAIN
###########################################################

localconf_filename = "localconf.yml"

if !File.exists?(localconf_filename)
  puts "Local config file not found - empty config file '#{localconf_filename}' will be created"
  puts "Please add configuration and try again"
  config_file = File.open(localconf_filename, "w")
  config_file.puts "username: test@gmail.com\npassword: hunter2\n"
  config_file.close
  exit false
end

localconf = YAML::load(File.read(localconf_filename))

bot = Discordrb::Bot.new localconf["username"], localconf["password"]

bot.message(with_text: "Ping!") do |event|
  event.respond "Pong!"
end

bot.include! GeneralAnnouncer
bot.include! FutileResponses
bot.include! GreetTheCommander
bot.include! AnnouncePossibleGames
bot.include! Pokedex

bot.run
