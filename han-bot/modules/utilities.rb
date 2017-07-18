
require 'discordrb'

require 'han-bot'
require 'han-lib'

module HanBot::Modules::Utilities
  extend Discordrb::EventContainer

  @@coin_phrases = [
    "I chose **@@@@** for you.",
    "**@@@@** it is.",
    "My dice said **@@@@**.",
    "My coin said **@@@@**.",
    "My DnD dice said **@@@@**.",
    "Roll for initiative! **@@@@**.",
    "Sorry I was so fast, I lost my coin. It seems to be **@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "**@@@@**.",
    "For the n+1-th time, it's **@@@@**.",
    "***Sy*ste*m malfu*nct*ion. Pl*ease t*rqy aqqqgain.***"
  ]

  @@games = [
    "Factorio",
    "World of Tanks",
    "Dark Souls III",
    "World of Warcraft",
    "Sins of a Solar Empire",
    "Gothic II (No Cheat Run)",
    "Battlefleet Gothic",
    "Age of Empires II",
    "Street Fighter Arcade Deluxe Ultimate Ultra Ω Z",
    "Diablo III",
    "Tom Clancy's The Division",
    "Tom Clancy's Ghost Recon Advanced Warfighter",
    "Tom Clancy's Splinter Cell",
    "Hearthstone - Heroes of Warcraft",
    "Warcraft III",
    "DotA 2",
    "Pokémon Go!",
    "Assetto Corsa",
    "Project Cars",
    "Elite Dangerous",
    "Star Citizen '18'"
    "Half Life 3",
    "Total War: Shogun II",
    "Total War: WARHAMMER",
    "The Elder Scrolls V: Skyrim Special Edition",
    "FEZ",
    "Grey Goo",
    "Borderlands",
    "Borderlands 2",
    "Borderlangs: The Pre-Sequel"
    "Minecraft"
  ]

  # builds a coin presentation phrase, where the announced coin result is the given value
  def self.coin_phrase(val)
    @@coin_phrases.sample.gsub(/@@@@/, val.to_s)
  end

  # gives you every single fucking rolled dice
  def self.dice_rolls(num_dices, dice_eyecount)
    (1..num_dices).map{ |i| [ i, (1..dice_eyecount).to_a.sample ] }
  end

  def self.change_game(bot)
    bot.game = @@games.sample
  end

  ready do |event|
    self.change_game event.bot
  end

  message(content: "#change-game")  do |event|
    self.change_game event.bot
  end

  message(start_with: /\#flipcoin/i) do |event|
    args = event.message.content.scan(/^\#flipcoin['" \|]*(.*?)$/i)[0][0]
    if args.length > 0
      event.respond self.coin_phrase(args.split(/['" \|]+/).sample)
    else
      event.respond self.coin_phrase(["Head", "Tail"].sample)
    end
  end

  message(start_with: /\#roll/i) do |event|
    args = event.message.content.scan(/^\#roll\s*(.*?)\s*$/i)[0][0]
    if args.length > 0
      if args =~ /^\d+$/
        upper_bound = args.to_i
        event.respond self.coin_phrase((1..upper_bound).to_a.sample)
      else
        scan = args.scan(/^(\d+)?[dw](\d+)(?:\s*\+\s*(\d+))?$/i)
        if scan.length == 0
          event.respond "Invalid roll value of '#{scan}'."
          break
        end
        scan = scan[0]
        num_dices = scan[0].to_i
        if !num_dices || num_dices == 0
          num_dices = 1
        end
        dice_eyecount = scan[1].to_i
        value_addition = scan[2].to_i
        if !value_addition
          value_addition = 0
        end

        dice_rolls = self.dice_rolls num_dices, dice_eyecount
        total = dice_rolls.inject(0){ |sum, val| sum + val[1] }
        total += value_addition
        eyecount_numbers = {}
        dice_rolls.map do |tup|
          val = tup[1]
          if !eyecount_numbers.has_key? val
            eyecount_numbers[val] = 0
          end
          eyecount_numbers[val] = eyecount_numbers[val] + 1
        end
        eyecount_numbers_sorted_keys = eyecount_numbers.keys.sort.reverse!.reverse!

        text = "Rolled: **#{total}**\n"
        text += "Single eyecounts:\n"
        text += eyecount_numbers_sorted_keys.map{ |key| "  - #{key}: #{eyecount_numbers[key]}x\n" }.join
        event.respond text
      end
    else
      event.respond self.coin_phrase((1..6).to_a.sample)
    end
  end

  message(start_with: "#spank") do |event|
    mentions = event.message.mentions.map(&:mention).join " "
    event.respond "#{mentions} bend over bitch and accept your punishment\nhttps://cdn.discordapp.com/attachments/107942652275601408/107945087350079488/TuHGJ.gif"
  end

  # invoke this command if you want to e.g. add new audio clips or memes, but don't want to restart the bot. for now, you also have to invoke e.g. #audio-load manually afterwards.
  message(content: "#git-pull") do |event|
    event.channel.split_send "Done.\n#{`cd #{HanBot.path} && git pull`}"
  end

  message(content: "#prune-channel") do |event|
    only_creator(event.user) {
      begin
        delete_count = 20
        channel = event.channel
        history = channel.history delete_count
        while history.length > 0
          channel.prune delete_count
          sleep 0.2
        end
      rescue Exception
        event.respond "#{event.user.mention} something seems to have gone wrong. A possible cause is that #{event.bot.bot_user.mention} does not have the appropriate permission to accomplish this action. Please contact this one's creator."
      end
    }
  end

  message(start_with: "#copy-channel") do |event|
    only_creator(event.user) {
      channelname = event.content.scan(/#copy-channel #?([^\s]+)/i)[0]
      puts channelname
      if !channelname
        next
      end
    }
  end

  # tells everybody how long the bot has been running. also tells everybody when I last restarted the bot.
  message(content: "#uptime") do |event|
    pid = Process.pid
    uptime = `ps -p #{pid} -o etime=`
    event.respond "I have been running for exactly **#{uptime.strip}**, and counting!"
  end

  @@last_logger_mode = nil

  # switches debug mode
  message(content: "#switch-debug-mode") do |event|
    only_creator(event.user) {
      if @@last_logger_mode == nil
        @@last_logger_mode = event.bot.mode
      end
      case event.bot.mode
        when :debug
          event.bot.mode = @@last_logger_mode
          @@last_logger_mode = nil
          event.send_message "Switched to *#{@@last_logger_mode}*."
        else
          @@last_logger_mode = event.bot.mode
          event.bot.mode = :debug
          event.send_message "Switched to *debug*."
      end
    }
  end

  @cream_trace = {}

  # generic error message to notify the user of a command written wrong.
  # TODO: give suggestions for what may have been correct.
  message(start_with: /[\#!~]/) do |event|
    command_name = event.message.content.scan(/^\#([^\s]+)/i)[0][0]
    if !event.bot.valid_command?(command_name)
      event.send_message "#{event.user.mention} that command does not exist."
      alternatives = event.bot.all_valid_commands.select do |command|
        target = [command.length, command_name.length].max / 3.0
        distance = Levenshtein.distance command_name, command
        distance < target
      end
      if !alternatives.empty?
        event.send_message "Did you mean:\n" + alternatives.map{ |s| "  - \##{s}\n" }.join
      end
      (@cream_trace ||= {})[conversation_id(event.user, event.channel)] = [
        event.message.content,
        alternatives
      ]
    end
  end

  message(content: /^[\#!~]?(fuck|shit|scheiße|verdammt|damn)\W*$/i) do |event|
    bot = event.bot
    channel = event.channel
    user = event.user

    cid = conversation_id user, channel
    invalid_command, suggestions = @cream_trace[cid]
    suggestions ||= [] # normalize to empty array if invalid
    invalid_command = nil if "".eql? invalid_command # normalize to nil for simple conditional handling

    if invalid_command && suggestions.length == 1
      event.respond "#{event.user.mention} ok fine, you win. I will just assume that was the British spelling for what you wanted."
      channel.start_typing

      suggestion = suggestions.first
      # compared to above this has some added characters since it may be only a missing space between the command name and the parameters
      command_name = invalid_command.scan(/^[\#!~]([^\s\d+]+)/i)[0][0]
      corrected_command = invalid_command.gsub(/(?<=[\#!~])#{command_name}\s*/, suggestion + " ").strip

      event.respond "***#{corrected_command}***"
      channel.start_typing
      sleep 0.250
      event.respond "_(whooooosh)_\n"
      channel.start_typing
      sleep 0.500

      message_data = {
        "id" => (Time.now.to_f * 1000 + Discordrb::DISCORD_EPOCH).to_i << 22,
        "content" => corrected_command,
        "bot" => bot,
        "author" => {"id" => user.id},
        "channel_id" => channel.id
      }
      message = Discordrb::Message.new message_data, bot
      message_event = Discordrb::Events::MessageEvent.new message, bot

      event.bot.send :raise_event, message_event
    elsif invalid_command && suggestions.length > 1
      event.respond "#{event.user.mention} sucks to be you. Too many choices for mighty _HanBot_!"
    elsif invalid_command && suggestions.length == 0
      event.respond "#{event.user.mention} excuse me please?"
    else
      event.respond "#{event.user.mention} muckst du dich? Hm? _Hm!?_ ***Hm!??***"
    end

    @cream_trace.delete cid
  end

  register_command "flipcoin"
  register_command "change-game"
  register_command "roll"
  register_command "spank"
  register_command "prune-channel"
  register_command "git-pull"
  register_command "uptime"
  register_command "switch-debug-mode"
  register_command "copy-channel"

  register_command "fuck"
  register_command "shit"
  register_command "scheiße"
  register_command "verdammt"

  help_text "**Utilities**\n" +
    "  _#flipcoin [<head-label> [<tail-label> [coin-butt-label]]]_\n" +
    "    Flips a coin. You can pass alternative names for head and/or tail if you like to. If you give it more options, it will pick one randomly.\n" +
    "  _#roll_ or _#roll w3_ or _#roll 2d6_ or _#roll d3+3_\n" +
    "    Simulates a dice roll. If you give it a dice-spec, it will roll within that range. @HanBot will detail the eye count numbers so you can e.g. choose re-rolls / read hit counts. Offsets apply to the total eye count.\n"
end
