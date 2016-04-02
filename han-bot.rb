require 'discordrb'
require 'yaml'
require 'net/http'
require 'uri'
require 'json'

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

bot.run
