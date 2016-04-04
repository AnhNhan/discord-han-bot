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
    "<@AnhNhan#> do I seriously have to respond to every single message? Those people are annoying.",
    "@@@@ _(pretends to be silent)_",
    "@@@@, I appreciate your attempt to communicate with me. But it is futile, for I am legion.",
    "I impersonate silence. I see no purpose in your action, @@@@."
  ]

  def self.pick_random_response(event)
    selected_response = @@responses.sample
    selected_response = selected_response.gsub "@@@@", event.user.mention
    return selected_response
  end

  mention do |event|
    event.respond self.pick_random_response(event)
  end

  pm(start_with: not!(/[\#!~]/)) do |event|
    event.respond self.pick_random_response(event)
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
      entry += "http://www.pokewiki.de/" + search["name_de"] + "\n"
      entry += imageurl + "\n"
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
    "My coin said **@@@@**.",
    "My DnD dice said **@@@@**.",
    "Roll for initiative! **@@@@**.",
    "Sorry I was so fast, I lost my coin. It seems to be **@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "For the n+1-th time, it's **@@@@**.",
    "***Sy*ste*m malfu*nct*ion. Pl*ease t*rqy aqqqgain.***"
  ]

  def self.coin_phrase(val)
    @@coin_phrases.sample.gsub /@@@@/, val.to_s
  end

  def self.dice_rolls(num_dices, dice_eyecount)
    (1..num_dices).map{ |i| [ i, (1..dice_eyecount).to_a.sample ] }
  end

  message(start_with: /\#flipcoin/i) do |event|
    args = event.message.content.scan(/^\#flipcoin['" \|]*(.*?)$/i)[0][0]
    if args.length > 0
      event.respond self.coin_phrase(args.split(/['" \|]+/).sample)
    else
      event.respond self.coin_phrase(["Head", "Tail"].sample)
    end
  end

  message(start_with: /\#roll/i) do |event|
    args = event.message.content.scan(/^\#roll\s*(.*?)\s*$/i)[0][0]
    if args.length > 0
      if args =~ /^\d+$/
        upper_bound = args.to_i
        event.respond self.coin_phrase((1..upper_bound).to_a.sample)
      else
        scan = args.scan /^(\d+)?[dw](\d+)(?:\s*\+\s*(\d+))?$/i
        if scan.length == 0
          event.respond "Invalid roll value of '#{scan}'."
          break
        end
        scan = scan[0]
        num_dices = scan[0].to_i
        if !num_dices || num_dices == 0
          num_dices = 1
        end
        dice_eyecount = scan[1].to_i
        value_addition = scan[2].to_i
        if !value_addition
          value_addition = 0
        end

        dice_rolls = self.dice_rolls num_dices, dice_eyecount
        total = dice_rolls.inject(0){ |sum, val| sum + val[1] }
        total += value_addition
        eyecount_numbers = {}
        dice_rolls.map do |tup|
          val = tup[1]
          if !eyecount_numbers.has_key? val
            eyecount_numbers[val] = 0
          end
          eyecount_numbers[val] = eyecount_numbers[val] + 1
        end
        eyecount_numbers_sorted_keys = eyecount_numbers.keys.sort.reverse!.reverse!

        text = "Rolled: **#{total}**\n"
        text += "Single eyecounts:\n"
        text += eyecount_numbers_sorted_keys.map{ |key| "  - #{key}: #{eyecount_numbers[key]}x\n" }.join
        event.respond text
      end
    else
      event.respond self.coin_phrase((1..6).to_a.sample)
    end
  end

  message(start_with: /\#spank @/) do |event|
    mentions = event.message.mentions.map(&:mention).join " "
    event.respond "#{mentions} bend over bitch and accept your punishment\nhttps://cdn.discordapp.com/attachments/107942652275601408/107945087350079488/TuHGJ.gif"
  end

  message(content: "#git-pull") do |event|
    event.respond "Done.\n#{`git pull`}"
  end

  message(content: "#prune-channel") do |event|
    if event.user.tag.eql? "6895"
      begin
        delete_count = 20
        channel = event.channel
        history = channel.history delete_count
        while history.length > 0
            channel.prune delete_count
            sleep 0.2
        end
      rescue Exception
        event.respond "#{event.user.mention} something seems to have gone wrong. A possible cause is that #{event.bot.bot_user.mention} does not have the appropriate permission to accomplish this action. Please contact its creator."
      end
    else
      event.respond "#{event.user.mention} you do not have permission to complete this command."
    end
  end
end

module AudioClips
  extend Discordrb::EventContainer

  def self.scan_files()
    Hash[ Dir.glob('./content/audioclips/**/*').select{ |e| File.file? e }.map{ |e| [File.basename(e, ".*"), e] } ]
  end

  @@audio_clip_map = self.scan_files()

  message(start_with: /\#/) do |event|
    clipname = event.message.content.scan(/^\#(.*?)\s*$/i)[0][0].downcase
    clip_exists = @@audio_clip_map.has_key? clipname
    if event && event.user.voice_channel && clip_exists
      channel = event.user.voice_channel
      if channel != event.bot.bot_user.voice_channel
        event.bot.voice_connect(channel)
        event.bot.voice.volume = 0.4
        event.bot.voice.adjust_average = false
        event.bot.voice.length_override = Discordrb::Voice::IDEAL_LENGTH - 6.5
      end
      event.bot.voice.play_io open(@@audio_clip_map[clipname])
    else
      if event && clip_exists
        if event.bot.voice # just play in the current channel
          event.user.pm "You currently don't seem to be in a voice channel, but I'm doing the courtesy nonetheless, just to annoy the other people. Playing _#{event.message.content}_!"
          event.bot.voice.play_io open(@@audio_clip_map[clipname])
        else # no channal found
          event.respond "#{event.user.mention} I'm sorry, you tried to play _#{clipname}_ but I could not find your current voice channel.\n_If you are already situated in one, please try re-joining, I'm not sure where the problem is exactly._\n_Or I just don't have access to your current channel._"
        end
      end
    end
  end

  message(content: "#audio-list") do |event|
    event.send_message @@audio_clip_map.keys.sort.reverse!.reverse!.map{ |k| "#" + k }.join("\n")
  end

  message(content: "#audio-reload") do |event|
    old_length = @@audio_clip_map.keys.length
    @@audio_clip_map = self.scan_files()
    new_length = @@audio_clip_map.keys.length
    event.respond "Done! Found #{new_length} files. Δ of #{new_length - old_length}."
  end

  message(content: "#audio-stop") do |event|
    event.bot.voice.stop_playing
    event.respond "Command received. Playback should stop within a few seconds."
  end

  message(content: "#audio-pause") do |event|
    event.bot.voice.pause
    event.respond "Command received. Playback should pause within a few seconds."
  end

  message(content: "#audio-continue") do |event|
    event.bot.voice.continue
    event.respond "Command received. Playback should continue within a few seconds."
  end
end

module HelpText
  extend Discordrb::EventContainer

  message(with_text: /^[!\#@~]help$/i) do |event|
    text = "**@HanBot Documentation Lite** (full version only available to creator)\n"
    text += "**Pokédex**\n"
    text += "  _#pokedex <search term>_\n"
    text += "    _<search term>_: Either the number of the Pokémon in the National-Dex, or its name in any of the following languages:\n"
    text += "                           German, English, French, Japanese, Korean (the last two also in its romanized variants).\n"
    text += "                           @HanBot will do its best to find you the appropriate entry and send you a quick summary of the Pokémon in question, with further information available on the PokéWiki.\n"
    text += "**Game Announcer**\n"
    text += "  @HanBot can announce possible games that can be played. Favorably when there are six people, then @HanBot will gladly suggest a round of Company of Heroes.\n"
    text += "**Utilities**\n"
    text += "  _#flipcoin [<head-label> [<tail-label> [coin-butt-label]]]_\n"
    text += "    Flips a coin. You can pass alternative names for head and/or tail if you like to. If you give it more options, it will pick one randomly.\n"
    text += "  _#roll_ or _#roll w3_ or _#roll 2d6_ or _#roll d3+3_\n"
    text += "    Simulates a dice roll. If you give it a dice-spec, it will roll within that range. @HanBot will detail the eye count numbers so you can e.g. choose re-rolls / read hit counts. Offsets apply to the total eye count.\n"
    text += "**Audio Clips**\n"
    text += "  _#audio-list_\n"
    text += "    lists all audio clip names"
    text += "  _#audio-stop_\n"
    text += "    Stops the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n"
    text += "  _#audio-pause_\n"
    text += "    Pauses the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n"
    text += "  _#audio-continue_\n"
    text += "    Continues the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n"

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
# bot.include! GreetTheCommander
bot.include! AnnouncePossibleGames
bot.include! Pokedex
bot.include! Utilities
bot.include! AudioClips
bot.include! HelpText

bot.run
