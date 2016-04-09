
require 'discordrb'

require 'han-bot'

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

  # builds a coin presentation phrase, where the announced coin result is the given value
  def self.coin_phrase(val)
    @@coin_phrases.sample.gsub /@@@@/, val.to_s
  end

  # gives you every single fucking rolled dice
  def self.dice_rolls(num_dices, dice_eyecount)
    (1..num_dices).map{ |i| [ i, (1..dice_eyecount).to_a.sample ] }
  end

  ready do |event|
    event.bot.game = "with this one itself"
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
        scan = args.scan /^(\d+)?[dw](\d+)(?:\s*\+\s*(\d+))?$/i
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
    event.respond "Done.\n#{`git pull`}"
  end

  message(content: "#prune-channel") do |event|
    if event.user.tag.eql? "6895"
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
    else
      event.respond "#{event.user.mention} you do not have permission to complete this command."
    end
  end

  # tells everybody how long the bot has been running. also tells everybody when I last restarted the bot.
  message(content: "#uptime") do |event|
    pid = Process.pid
    uptime = `ps -p #{pid} -o etime=`
    event.respond "I have been running for exactly **#{uptime.strip}**, and counting!"
  end

  # generic error message to notify the user of a command written wrong.
  # TODO: give suggestions for what may have been correct.
  message(start_with: /[\#!~]/) do |event|
    command_name = event.message.content.scan(/^\#([^\s]+)/i)[0][0]
    if !HanBot.valid_command?(command_name)
      event.send_message "#{event.user.mention} that command does not exist."
    end
  end
end
