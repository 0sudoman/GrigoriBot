import os
import os.path
import sys
import discord
import asyncio

client = discord.Client()

@client.event
async def on_message(message):
  if message.content.startswith('!release'):
    if(os.path.isfile("todiscord")):
      file = open("todiscord")
      for line in file:
        await client.send_message(message.channel, line.rstrip())
      file.close
      os.remove("todiscord")
  if message.content.startswith('!source'):
    await client.send_message(message.channel, "https://github.com/0sudoman/GrigoriBot")

client.run(sys.argv[1])
