
# generates a conversation id for a conversation a user has with the bot
def conversation_id(user, channel)
  user.id.to_s + "::" + if channel then channel.id.to_s else "private-conversation" end
end
