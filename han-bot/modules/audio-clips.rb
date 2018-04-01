
require 'discordrb'

require 'han-bot'

module HanBot::Modules::AudioClips
  extend Discordrb::EventContainer
  cattr_accessor :audio_clip_map

  # scans for audio files in the content directory
  def self.scan_files()
    Hash[ Dir.glob(HanBot.path('content/audioclips/**/*')).select{ |e| File.file? e }.map{ |e| [File.basename(e, ".*"), e] } ]
  end

  @audio_clip_map = self.scan_files()

  message(start_with: /\#/) do |event|
    match = event.message.content.scan(/^\#([^\s]+)(?:\s+([^\s]+))?\s*$/i)[0]
    if !match
      next
    end
    clipname = match[0].downcase
    if event.bot.valid_command?(clipname)
      next
    end
    clip_exists = @audio_clip_map.has_key? clipname

    server_name = nil
    if event.channel.private? && match[1]
      server_name = match[1]
      server_name_dc = server_name.downcase
      server = event.bot.servers.values.find{ |server| server.name.downcase.eql? server_name_dc }

      if server && event.bot.voice(server)
        voice_bot = event.bot.voice server
        user_channel = voice_bot.instance_variable_get :@channel
      elsif server
        event.respond "#{event.user.mention} sorry, but I'm currently not talking on '_#{server_name}_'."
        next
      else
        event.respond "#{event.user.mention} sorry, but I could not find the server '_#{server_name}_'."
        next
      end
    elsif match[1]
      # event.respond "#{event.user.mention} sorry, but server-specific play commands must be sent over private messages to reduce littering on channels _(and to maintain discretion :smiling_imp:)_."
      next
    else
      user_channel = HanBot.current_voice_channel event.user, event.bot
    end

    if event && event.channel && user_channel && clip_exists
      voice = event.bot.voice user_channel
      if voice && voice != user_channel
        # already connected on the server, but not in this channel
        # just reset voice to connect to the proper channel
        voice = nil
      end
      if !voice
        voice = event.bot.voice_connect user_channel
        voice.filter_volume = 0.4
        voice.adjust_average = false
        voice.length_override = Discordrb::Voice::IDEAL_LENGTH - 5
      # don't use existing voice bot - it may be in the wrong channel
      # elsif event.voice
      #   voice = event.voice
      end

      if !voice # still no voice
        event.respond "#{event.user.mention} I'm sorry, there was an application error. Please contact my creator and tell him what happened."
        raise "Voice application error here. Probably wrong API usage."
      end

      voice.play_io open(@audio_clip_map[clipname])
    elsif event && clip_exists
      event.respond "#{event.user.mention} I'm sorry, you tried to play _#{clipname}_ but I could not find your current voice channel.\n_Or I just don't have access to your current channel. Always a possibility._"
    end
  end

  message(content: "#audio-list") do |event|
    event.channel.split_send @audio_clip_map.keys.map{ |s| "#" + s }.sort.reverse!.reverse!.join("\n")
  end

  message(content: "#audio-reload") do |event|
    old_length = @audio_clip_map.keys.length
    @audio_clip_map = self.scan_files()
    new_length = @audio_clip_map.keys.length
    event.respond "Done! Found #{new_length} files. Δ of #{new_length - old_length}."
  end

  message(content: "#audio-stop") do |event|
    event.bot.voice(HanBot.current_voice_channel(event.user, event.bot)).stop_playing
    event.respond "Command received. Playback should stop within a few seconds."
  end

  message(content: "#audio-pause") do |event|
    event.bot.voice(HanBot.current_voice_channel(event.user, event.bot)).pause
    event.respond "Command received. Playback should pause within a few seconds."
  end

  message(content: "#audio-continue") do |event|
    event.bot.voice(HanBot.current_voice_channel(event.user, event.bot)).continue
    event.respond "Command received. Playback should continue within a few seconds."
  end

  register_command "audio-list"
  register_command "audio-reload"
  register_command "audio-stop"
  register_command "audio-pause"
  register_command "audio-continue"

  add_valid_command_callback { |str| @audio_clip_map.has_key?(str) }

  add_valid_command_list_callback { || @audio_clip_map.keys }

  help_text     "**Audio Clips**\n" +
    "  _#audio-list_\n" +
    "    lists all audio clip names"
    "  _#audio-stop_\n" +
    "    Stops the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n" +
    "  _#audio-pause_\n" +
    "    Pauses the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n" +
    "  _#audio-continue_\n" +
    "    Continues the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n"
end
