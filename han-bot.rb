require 'discordrb'
require 'yaml'

localconf_filename = "localconf.yml"

if !File.exists?(localconf_filename)
  puts "Local config file not found - empty config will be created"
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

bot.run
