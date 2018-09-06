**GrigoriBot**

This bot was designed to simplify the sorting process for new TV shows.
Its main purpose is to take a directory name from IRC (or bash), then automaticially sort it into the appropiate show/season folder.
It notifies IRC, Discord, Pushbullet, and a logfile after it is finished.

I built this in my free time, so don't expect anything fancy. Or functional, for that matter.

GrigoriBot requires `screen` to keep things running in the background.
You can easily change this to `tmux` or your multiplexer of choice.
It uses `ii` to interface with IRC, but can be modifed to work with `irssi`.
Pushbullet is connected through `pushbullet-bash`, available on GitHub.
The fortune command requires `fortune` to be installed. Obviously.

Before running GrigoriBot for the first time, be sure to customize your config.sh script.
You will need to edit the values, then rename it to config.sh (from config.sh.example).
