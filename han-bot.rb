require 'rbnacl/libsodium'
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

  @@responses = [
    "@@@@, it is meaningless to converse with a soulless machine.",
    "@@@@, there is no hope in talk with me.",
    "<@AnhNhan> do I seriously have to respond to every single message? Those people are annoying.",
    "@@@@ _(pretends to be silent)_",
    "@@@@, I appreciate your attempt to communicate with me. But it is futile, for I am legion.",
    "I impersonate silence. I see no purpose in your action, @@@@."
  ]

  def self.pick_random(event)
    selected_response = @@responses.sample
    selected_response = selected_response.gsub "@@@@", event.user.mention
    return selected_response
  end

  mention do |event|
    event.respond self.pick_random(event)
  end

  pm do |event|
    break unless event.message.content[0] =~ /[\#|!]/
    event.respond self.pick_random(event)
  end
end

module GreetTheCommander
  extend Discordrb::EventContainer

  @@weather_uri_ansbach = URI("http://api.openweathermap.org/data/2.5/weather?id=2955936&units=metric&appid=689642cefcdae7cb38b5e6070034f31e")

  presence do |event|
    if event.server && "AnhNhan".eql?(event.user.name) && :online.eql?(event.status)
      weather_data = JSON.parse(Net::HTTP.get(@@weather_uri_ansbach))
      current_temp = weather_data["main"]["temp"]
      # event.server.general_channel.send_message "#{event.user.mention}\nWelcome back, commander!\nCurrent temperature is #{current_temp}°C.\nReactor online.\nSensors online.\nWeapons online.\nAll systems nominal.", true
      event.server.general_channel.send_message "#{event.user.mention}\nWillkommen zurück, Commander.\nDie derzeitige Temperatur beträgt #{current_temp}°C.\nReaktor online.\Sensoren online.\Waffensysteme online.\nAlle Systeme nominal.", true
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
      query = query.gsub /^\#?0+/, ""
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
      imageinfo_api_uri = URI("http://www.pokewiki.de/api.php?action=query&format=json&prop=imageinfo&titles=Datei:Sugimori_" + search["id"] + ".png&iiprop=url")
      imageinfo = JSON.parse(Net::HTTP.get(imageinfo_api_uri))
      imageurl = imageinfo["query"]["pages"].values[0]["imageinfo"][0]["url"]

      entry = "**Pokédex-Eintrag *\#" + search["id"] + "***\n"
      entry += "**" + search["name_de"] + "**" + self.foreignnames(entry, ["name_en", "name_jpr"]) + "\n"
      entry += "Typ: _" + search["type"].join("_, _") + "_\n"
      entry += imageurl + "\n"
      entry += "http://www.pokewiki.de/" + search["name_de"] + "\n"
      event.send_message entry
    else
      event.send_message "#{event.user.mention} '#{query_string}' could not be found in the Pokédex."
    end
  end

  def self.foreignnames(entry, indexes)
    snippets = Array.new
    indexes.each do |index|
      name = entry[index]
      lang = index.gsub "name_", ""
      lang = lang.slice 0, 2 # remove romanization denotation suffix
      snippets.push lang + ".: " + name
    end
    return "" unless snippets.length
    return " (" + snippets.join(", ") + ")"
  end
end

module Utilities
  extend Discordrb::EventContainer

  @@coin_phrases = [
    "I chose **@@@@** for you.",
    "**@@@@** it is.",
    "My dice said **@@@@**.",
    "Sorry I was so fast, I lost my coin. It seems to be **@@@@**.",
    "**@@@@**.",
    "For the n+1-th time, it's **@@@@**.",
    "***Sy*ste*m malfu*nct*ion. Pl*ease t*rqy aqqqgain.***"
  ]

  def self.coin_phrase(val)
    @@coin_phrases.sample.gsub /@@@@/, val
  end

  message(start_with: /\#flipcoin/i) do |event|
    args = event.message.content.scan(/^\#flipcoin['" \|]*(.*?)$/i)[0][0]
    if args.length > 0
      event.respond self.coin_phrase(args.split(/['" \|]+/).sample)
    else
      event.respond self.coin_phrase(["Head", "Tail"].sample)
    end
  end
end

module AudioClips
  extend Discordrb::EventContainer

  @@audio_clip_map = Hash[ Dir.glob('./content/audioclips/**/*.mp3').select{ |e| File.file? e }.map{ |e| [File.basename(e, ".*"), e] } ]

  message(start_with: /\#/) do |event|
    clipname = event.message.content.scan(/^\#(.*?)\s*$/i)[0][0].downcase
    clip_exists = @@audio_clip_map.has_key? clipname
    if event && event.user.voice_channel
      if clip_exists
        channel = event.user.voice_channel
        voice = event.bot.voice_connect(channel)
        old_volume = voice.volume
        voice.volume = 0.5
        voice.play_file @@audio_clip_map[clipname]
        voice.volume = old_volume
      end
    else
      if event && clip_exists
        event.respond "#{event.user.mention} I'm sorry, you tried to play _#{clipname}_ but I could not find your current voice channel.\n_If you are already situated in one, please try re-joining, I'm not sure where the problem is exactly._"
      end
    end
  end
end

module HelpText
  extend Discordrb::EventContainer

  message(with_text: /^!help$/i) do |event|
    text = "**@HanBot Documentation Lite** (full version only available to creator)\n"
    text += "**Pokédex**\n"
    text += "  _#pokedex <search term>_\n"
    text += "    _<search term>_: Either the number of the Pokémon in the National-Dex, or its name in any of the following languages:\n"
    text += "                           German, English, French, Japanese, Korean (the last two also in its romanized variants).\n"
    text += "                           @HanBot will do its best to find you the appropriate entry and send you a quick summary of the Pokémon in question, with further information available on the PokéWiki.\n"
    text += "**Game Announcer**\n"
    text += "  @HanBot can announce possible games that can be played. Favorably when there are six people, then I will gladly suggest a round of Company of Heroes.\n"
    text += "**Utilities**\n"
    text += "  _#flipcoin [<head-label> [<tail-label>]]_\n"
    text += "    Flips a coin. You can pass alternative names for head and/or tail if you like to.\n"

    event.send_message text
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

bot.message(with_text: /^\W*ping\W*$/i) do |event|
  event.respond "Pong!"
end

bot.include! GeneralAnnouncer
bot.include! FutileResponses
bot.include! GreetTheCommander
bot.include! AnnouncePossibleGames
bot.include! Pokedex
bot.include! Utilities
bot.include! AudioClips
bot.include! HelpText

bot.run
