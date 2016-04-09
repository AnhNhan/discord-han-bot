
require 'discordrb'
require 'json'
require 'net/http'
require 'uri'
require 'levenshtein'

module HanBot::Modules::Pokedex
  extend Discordrb::EventContainer

  def self.load()
    JSON.parse(File.read(HanBot.path("pokemon-list.json")))
  end

  @pokedex = self.load()
  @@name_search_indexes = [ "name_de", "name_en", "name_fr", "name_jp", "name_jpr", "name_kr", "name_krr" ]

  # searches through the pokedex for an entry with a possibly matching name
  # note that the current heuristics is to traverse the pokedex entries matching the names exactly, and if no match has been found, traverse it again with broader constraints
  def self.search_pokemon(query, current_level = 0, max_level = 3)
    if query =~ /^\d+$/
      # search by id
      #
      # strip all leading zeros and re-pad them later again
      # this is necessary since the user might input too many zeroes
      query = query.gsub /^\#?0+/, ""
      query = query.rjust(3, "0")
      return @pokedex.find{ |entry| query.eql? entry["id"] }
    else
      # search by name
      # slighty fuzzy search, not too fast, not too precise, pokemon with similar name may be mistaken
      query = query.downcase.gsub /\s/, ""
      #puts "current query: #{query}"
      return nil if !query

      result = @pokedex.find do |entry|
        entryname = entry["name_de"]
        #puts "at entry: #{entryname}"
        @@name_search_indexes.find do |index|
          current_hayneedle = entry[index].downcase.gsub /\s/, ""
          next if !current_hayneedle
          distance_target = current_level
          distance = Levenshtein.distance query, current_hayneedle
          #puts "#{current_hayneedle}: #{distance} -- #{distance_target}"
          distance * 1.0 <= distance_target
        end
      end

      if !result && current_level < max_level
        result = self.search_pokemon query, current_level + 1, max_level
      end
      result
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
      entry += "**" + search["name_de"] + "**" + self.foreignnames(search, ["name_en", "name_jpr"]).to_s + "\n"
      entry += "Typ: _" + search["type"].join("_, _") + "_\n"
      entry += "http://www.pokewiki.de/" + search["name_de"] + "\n"
      entry += imageurl + "\n"
      event.send_message entry
    else
      event.send_message "#{event.user.mention} '#{query_string}' could not be found in the Pokédex."
    end
  end

  message(content: "#pokedex-reload") do |event|
    old_length = @pokedex.length
    @pokedex = self.load()
    new_length = @pokedex.length
    event.respond "Done! Found #{new_length} Pokémon. Δ of #{new_length - old_length}."
  end

  # compiles the entry's various names into a short presentable list
  def self.foreignnames(entry, indexes, separator = ", ", prefix = " (", suffix= ")")
    snippets = Array.new
    indexes.each do |index|
      name = entry[index]
      lang = index.gsub "name_", ""
      lang = lang.slice 0, 2 # remove romanization denotation suffix
      snippets.push lang + ".: " + name
    end
    if snippets.length > 0
      prefix + snippets.join(separator) + suffix
    else
      ""
    end
  end

  register_command "pokedex"
  register_command "pokedex-reload"

  help_text(
    "**Pokédex**\n" +
    "  _#pokedex <search term>_\n" +
    "    _<search term>_: Either the number of the Pokémon in the National-Dex, or its name in any of the following languages:\n" +
    "                           German, English, French, Japanese, Korean (the last two also in its romanized variants).\n" +
    "                           @HanBot will do its best to find you the appropriate entry and send you a quick summary of the Pokémon in question, with further information available on the PokéWiki.\n"
  )
end
