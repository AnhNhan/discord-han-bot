
module HanBot
  cattr_accessor :localconf_filename

  @@localconf_filename = "localconf.yml"
  @@_global_commands = [
    "help",
    "pokedex",
    "flipcoin",
    "roll",
    "spank",
    "prune-channel",
    "git-pull",
    "uptime",
    "audio-list",
    "audio-reload",
    "audio-stop",
    "audio-pause",
    "audio-continue",
    "meme-list",
    "meme-reload"
  ]

  @@_valid_command_callbacks = []

  def HanBot.add_valid_command_callback(&cb)
    @@_valid_command_callbacks.push cb
  end

  def HanBot.valid_command?(str)
    str = str.downcase.strip
    HanBot._global_commands.include?(str) || @@_valid_command_callbacks.map{ |cb| cb.call(str) }.any?
  end

  def HanBot.current_voice_channel(user, bot)
    bot.servers.each do |server|
      member = user.on server[1] # for some reason I get [id, server] tuples in the server symbol
      return member.voice_channel if member.voice_channel
    end
    nil
  end
end

module HanBot::Modules
end
