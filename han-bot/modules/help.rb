
require 'discordrb'

module HanBot::Modules::HelpText
  extend Discordrb::EventContainer

  message(with_text: /^[!\#@~]help$/i) do |event|
    text = "**@HanBot Documentation Lite** (full version only available to creator)\n"
    text += event.bot.help_texts
    event.send_message text
  end

  register_command "help"
end
