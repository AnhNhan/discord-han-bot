
require 'discordrb'
require 'net/http'
require 'uri'
require 'json'

module HanBot::Modules::GeneralAnnouncer
  extend Discordrb::EventContainer

  member_join do |event|
    event.server.general_channel.send_message "#{event.user.mention} joined! Please welcome him!"
  end

  member_leave do |event|
    event.server.general_channel.send_message "#{event.user.mention} left the server. He better had a reason to."
  end
end

module HanBot::Modules::FutileResponses
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

module HanBot::Modules::GreetTheCommander
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

module HanBot::Modules::AnnouncePossibleGames
  extend Discordrb::EventContainer

  presence do |event|
    if event.server
      #TODO: Support other bot recognition. Username-based, anyone?
      online_users = event.server.users.select{ |u| !u.bot_account? && u.status.eql?(:online) }
      if online_users.length == 6
        online_user_names = online_users.map(&:name).join ", "
        event.server.general_channel.send_message "There are a total of six people online. Perfect for a Company of Heroes match on The Sheldt!\n(#{online_user_names})"
      end
    end
  end
end
