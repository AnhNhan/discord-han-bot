
require 'discordrb'
require 'net/http'
require 'uri'
require 'json'
require 'levenshtein'

# Monkey Patch Basis
module HanBot::Modules::ExtendedEventContainer
  @help_text = ""
  @help_texts = []

  @registered_commands = []
  @valid_command_callbacks = []
  @valid_command_list_callbacks = []

  @@creator_discriminator = "6895"

  def is_creator?(user)
    user.discriminator.eql? @@creator_discriminator
  end

  def only_creator(user, &cb)
    if is_creator? user
      cb.call
    else
      event.respond "#{user.mention} you do not have permission to complete this command."
    end
  end

  def help_text(text = nil)
    if text
      @help_text = text
    else
      @help_text
    end
  end

  def help_texts()
    @help_texts.join
  end

  def clear_help_text()
    @help_text = ""
  end

  def clear_help_texts()
    @help_texts = []
  end

  def register_command(command)
    (@registered_commands ||= [])  << command
  end

  def add_valid_command_callback(&cb)
    (@valid_command_callbacks ||= [])  << cb
  end

  def add_valid_command_list_callback(&cb)
    (@valid_command_list_callbacks ||= [])  << cb
  end

  def valid_command?(command)
    command = command.downcase.strip
    (@registered_commands || []).include?(command) || (@valid_command_callbacks || []).map{ |cb| cb.call(command) }.any?
  end

  def all_valid_commands()
    (@registered_commands || []) + (@valid_command_list_callbacks || []).map{ |cb| cb.call() }.flatten
  end

  def hanbot_include!(container)
    include! container

    help_text = container.instance_variable_get :@help_text
    if help_text && help_text.length > 0
      @help_texts.push help_text
    end

    registered_commands = container.instance_variable_get :@registered_commands
    if registered_commands && registered_commands.length > 0
      @registered_commands += registered_commands
    end

    valid_command_callbacks = container.instance_variable_get :@valid_command_callbacks
    if valid_command_callbacks && valid_command_callbacks.length > 0
      @valid_command_callbacks += valid_command_callbacks
    end

    valid_command_list_callbacks = container.instance_variable_get :@valid_command_list_callbacks
    if valid_command_list_callbacks && valid_command_list_callbacks.length > 0
      @valid_command_list_callbacks += valid_command_list_callbacks
    end
  end
end

# Monkey-patch
module Discordrb::EventContainer
  include HanBot::Modules::ExtendedEventContainer
end
class Discordrb::Bot
  include HanBot::Modules::ExtendedEventContainer

  # additional monkey patch because this is a class and class instance attributes have to be initialized in the constructor
  old_initialize = instance_method(:initialize)

  define_method(:initialize) do |email: nil, password: nil, log_mode: :normal,
      token: nil, application_id: nil,
      type: nil, name: '', fancy_log: false, suppress_ready: false, parse_self: false|
    @help_text = ""
    @help_texts = []
    @registered_commands = []
    @valid_command_callbacks = []
    @valid_command_list_callbacks = []

    old_initialize.bind(self).(email: email, password: password, log_mode: log_mode, token: token, application_id: application_id, type: type, name: name, fancy_log: fancy_log, suppress_ready: suppress_ready, parse_self: parse_self)
  end
end

module HanBot::Modules::GeneralAnnouncer
  extend Discordrb::EventContainer

  member_join do |event|
    event.server.general_channel.send_message "#{event.user.mention} joined! Please welcome him!"
  end

  member_leave do |event|
    event.server.general_channel.send_message "#{event.user.mention} left the server. He better had a reason to."
  end

  help_text "**Game Announcer**\n" +
    "  @HanBot can announce possible games that can be played. Favorably when there are six people, then @HanBot will gladly suggest a round of Company of Heroes.\n"
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

  pm(start_with: not!(/[\#!~]|fuck|shit|verdammt|scheiße/i)) do |event|
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
