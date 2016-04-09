
require 'discordrb'

require 'han-bot'

module HanBot::Modules::AudioClips
  extend Discordrb::EventContainer
  cattr_accessor :audio_clip_map

  # scans for audio files in the content directory
  def self.scan_files()
    Hash[ Dir.glob('./content/audioclips/**/*').select{ |e| File.file? e }.map{ |e| [File.basename(e, ".*"), e] } ]
  end

  @@audio_clip_map = self.scan_files()

  message(start_with: /\#/) do |event|
    clipname = event.message.content.scan(/^\#(.*?)\s*$/i)[0][0].downcase
    clip_exists = @@audio_clip_map.has_key? clipname
    user_channel = HanBot.current_voice_channel event.user, event.bot
    if event && event.channel && user_channel && clip_exists
      voice = event.bot.voice user_channel
      if voice && voice != user_channel
        # already connected on the server, but not in this channel
        # just reset voice to connect to the proper channel
        voice = nil
      end
      if !voice
        voice = event.bot.voice_connect user_channel
        voice.volume = 0.4
        voice.adjust_average = false
        voice.length_override = Discordrb::Voice::IDEAL_LENGTH - 6.5
      # don't use existing voice bot - it may be in the wrong channel
      # elsif event.voice
      #   voice = event.voice
      end

      if !voice # still no voice
        event.respond "#{event.user.mention} I'm sorry, there was an application error. Please contact my creator and tell him what happened."
        raise "Voice application error here. Probably wrong API usage."
      end

      voice.play_io open(@@audio_clip_map[clipname])
    elsif event && clip_exists
      event.respond "#{event.user.mention} I'm sorry, you tried to play _#{clipname}_ but I could not find your current voice channel.\n_Or I just don't have access to your current channel. Always a possibility._"
    end
  end

  message(content: "#audio-list") do |event|
    event.send_message @@audio_clip_map.keys.sort.reverse!.reverse!.join("\n")
  end

  message(content: "#audio-reload") do |event|
    old_length = @@audio_clip_map.keys.length
    @@audio_clip_map = self.scan_files()
    new_length = @@audio_clip_map.keys.length
    event.respond "Done! Found #{new_length} files. Δ of #{new_length - old_length}."
  end

  message(content: "#audio-stop") do |event|
    event.bot.voice(current_voice_channel(event.user, event.bot)).stop_playing
    event.respond "Command received. Playback should stop within a few seconds."
  end

  message(content: "#audio-pause") do |event|
    event.bot.voice(current_voice_channel(event.user, event.bot)).pause
    event.respond "Command received. Playback should pause within a few seconds."
  end

  message(content: "#audio-continue") do |event|
    event.bot.voice(current_voice_channel(event.user, event.bot)).continue
    event.respond "Command received. Playback should continue within a few seconds."
  end
end
