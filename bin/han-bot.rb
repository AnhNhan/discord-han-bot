
$LOAD_PATH << (File.dirname(__FILE__) + "/../han-bot/")

begin
  require 'rbnacl/libsodium'
rescue LoadError
  ::RBNACL_LIBSODIUM_GEM_LIB_PATH = File.dirname(__FILE__) + "/libsodium.dll"
end

require 'discordrb'
require 'yaml'


require 'han-bot'
require 'modules/general'
require 'modules/audio-clips'
require 'modules/memes'
require 'modules/pokedex'
require 'modules/utilities'
require 'modules/help'

###########################################################
#### MAIN
###########################################################

if !File.exists?(HanBot.localconf_filename)
  puts "Local config file not found - empty config file '#{HanBot.localconf_filename}' will be created"
  puts "Please add configuration and try again"
  config_file = File.open(HanBot.localconf_filename, "w")
  config_file.puts "username: test@gmail.com\npassword: hunter2\nwolfram:\n  appip: appid-here\ntoken: ''\nappid: 0\n"
  config_file.close
  exit false
end

localconf = YAML::load(File.read(HanBot.localconf_filename))

bot = nil
if localconf["token"] && localconf["token"].length && localconf["appid"] != 0
  bot = Discordrb::Bot.new token: localconf["token"], application_id: localconf["appid"]
elsif localconf["username"].length != 0 && localconf["password"].length != 0
  bot = Discordrb::Bot.new email: localconf["username"], password: localconf["password"]
else
  puts "No authentication info, check localconf.yml."
  exit false
end

bot.message(with_text: /^\W*ping\W*$/i) do |event|
  event.respond "Pong!"
end

bot.include! HanBot::Modules::GeneralAnnouncer
bot.include! HanBot::Modules::FutileResponses
# bot.include! HanBot::Modules::GreetTheCommander
bot.include! HanBot::Modules::AnnouncePossibleGames
bot.include! HanBot::Modules::Pokedex
bot.include! HanBot::Modules::Utilities
bot.include! HanBot::Modules::AudioClips
bot.include! HanBot::Modules::Memes
bot.include! HanBot::Modules::HelpText

# register modules for command validation
HanBot.add_valid_command_callback { |str| HanBot::Modules::AudioClips.audio_clip_map.has_key?(str) }
HanBot.add_valid_command_callback { |str| HanBot::Modules::Memes.memes.has_key?(str) }

bot.run
