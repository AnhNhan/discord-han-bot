
require 'discordrb'

module HanBot::Modules::HelpText
  extend Discordrb::EventContainer

  message(with_text: /^[!\#@~]help$/i) do |event|
    text = "**@HanBot Documentation Lite** (full version only available to creator)\n"
    text += "**Pokédex**\n"
    text += "  _#pokedex <search term>_\n"
    text += "    _<search term>_: Either the number of the Pokémon in the National-Dex, or its name in any of the following languages:\n"
    text += "                           German, English, French, Japanese, Korean (the last two also in its romanized variants).\n"
    text += "                           @HanBot will do its best to find you the appropriate entry and send you a quick summary of the Pokémon in question, with further information available on the PokéWiki.\n"
    text += "**Game Announcer**\n"
    text += "  @HanBot can announce possible games that can be played. Favorably when there are six people, then @HanBot will gladly suggest a round of Company of Heroes.\n"
    text += "**Utilities**\n"
    text += "  _#flipcoin [<head-label> [<tail-label> [coin-butt-label]]]_\n"
    text += "    Flips a coin. You can pass alternative names for head and/or tail if you like to. If you give it more options, it will pick one randomly.\n"
    text += "  _#roll_ or _#roll w3_ or _#roll 2d6_ or _#roll d3+3_\n"
    text += "    Simulates a dice roll. If you give it a dice-spec, it will roll within that range. @HanBot will detail the eye count numbers so you can e.g. choose re-rolls / read hit counts. Offsets apply to the total eye count.\n"
    text += "**Audio Clips**\n"
    text += "  _#audio-list_\n"
    text += "    lists all audio clip names"
    text += "  _#audio-stop_\n"
    text += "    Stops the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n"
    text += "  _#audio-pause_\n"
    text += "    Pauses the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n"
    text += "  _#audio-continue_\n"
    text += "    Continues the current playback. Note that there are playback- and netword-related delays, so give it a few seconds.\n"

    event.send_message text
  end
end
