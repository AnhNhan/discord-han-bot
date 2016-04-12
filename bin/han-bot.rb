
$LOAD_PATH << (File.dirname(__FILE__) + "/../han-bot/")

begin
  require 'rbnacl/libsodium'
rescue LoadError
  ::RBNACL_LIBSODIUM_GEM_LIB_PATH = File.dirname(__FILE__) + "/libsodium.dll"
end

require 'discordrb'
require 'slop'
require 'yaml'


require 'han-bot'
require 'modules/general'
require 'modules/audio-clips'
require 'modules/memes'
require 'modules/pokedex'
require 'modules/utilities'
require 'modules/help'
require 'modules/invite-bot'

###########################################################
#### MAIN
###########################################################

opts = Slop.parse do |o|
  o.bool "-d", "--debug", "enable debug logging via Discordrb::Logger"
  o.on "--version", "print the version" do
    puts Slop::VERSION
    exit
  end
end

if !File.exists?(HanBot.localconf_filename)
  puts "Local config file not found - empty config file '#{HanBot.localconf_filename}' will be created"
  puts "Please add configuration and try again"
  config_file = File.open(HanBot.localconf_filename, "w")
  config_file.puts "username: test@gmail.com\npassword: hunter2\nwolfram:\n  appip: appid-here\ntoken: ''\nappid: 0\n"
  config_file.close
  exit false
end

localconf = YAML::load(File.read(HanBot.localconf_filename))
log_mode = if opts[:debug] then :debug else :normal end

bot = nil
if localconf["token"] && localconf["token"].length && localconf["appid"] != 0
  bot = Discordrb::Bot.new token: localconf["token"], application_id: localconf["appid"], log_mode: log_mode
elsif localconf["username"].length != 0 && localconf["password"].length != 0
  bot = Discordrb::Bot.new email: localconf["username"], password: localconf["password"], log_mode: log_mode
else
  puts "No authentication info, check localconf.yml."
  exit false
end

bot.message(with_text: /^\W*ping\W*$/i) do |event|
  event.respond "Pong!"
end

bot.hanbot_include! HanBot::Modules::GeneralAnnouncer
bot.hanbot_include! HanBot::Modules::FutileResponses
# bot.hanbot_include! HanBot::Modules::GreetTheCommander
bot.hanbot_include! HanBot::Modules::AnnouncePossibleGames
bot.hanbot_include! HanBot::Modules::Pokedex
bot.hanbot_include! HanBot::Modules::Utilities
bot.hanbot_include! HanBot::Modules::AudioClips
bot.hanbot_include! HanBot::Modules::Memes
bot.hanbot_include! HanBot::Modules::HelpText
bot.hanbot_include! HanBot::Modules::InviteBot

bot.run
