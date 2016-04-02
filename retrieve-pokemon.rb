require 'json'
require 'uri'
require 'net/http'

locale_suffix = {
  2 => "de",
  3 => "en",
  4 => "fr",
  5 => "jp",
  6 => "jpr",
  7 => "kr",
  8 => "krr"
}

pokemon_list_entries = Array.new

pokemon_list_uri = URI "http://www.pokewiki.de/api.php?action=query&prop=revisions&rvprop=content&titles=Pok%C3%A9mon-Liste&format=json"

puts "Retrieving latest list from pokewiki.de"

pokemon_list_response = JSON.parse Net::HTTP.get(pokemon_list_uri)
pokemon_list_raw_text = pokemon_list_response["query"]["pages"]["2366"]["revisions"][0]["*"]

puts "Retrieved list, processing now"

pokemon_list_raw_text.split("\n").select{ |i| i[/^\|\s*(<.*?>)?\s*\d+\s*\|\|/] }.each do |line|
  entry = {}
  column_index = 0
  line.split(/\s+\|+\s+/).map(&:chomp).select{ |i| i[/^(?!style=)/] }.each do |column|
    case column_index
      when 0
        column.gsub! /\s|\||<.*?>/, ""
        entry["id"] = column
      when 2
        column.gsub! /(^\[\[)|(\]\]$)/, ""
        entry["name_de"] = column
      when 3..8
        entry["name_" + locale_suffix[column_index]] = column
      when 9
        types = column.scan /(?<=\{\{IC\|).*?(?=\}\})/
        entry["type"] = types
    end
    column_index += 1
  end
  pokemon_list_entries.push entry
end

puts "Processing done, found #{pokemon_list_entries.length} Pokemon, writing to pokemon-list.json"

File.open("pokemon-list.json", "w") do |file|
  file.write pokemon_list_entries.to_json
  puts "Writing successful"
  puts "** DONE **"
end
