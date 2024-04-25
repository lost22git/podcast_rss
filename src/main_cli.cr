require "./command"

# PodcastRss::Repo.exec_init_sql

# rss_list = [
#   "http://rss.lizhi.fm/rss/14275.xml",
#   "http://www.ximalaya.com/album/4494083.xml",
#   "https://s1.proxy.wavpub.com/storyhunting.xml",
# ]

command_parser = PodcastRss::CommandParser.new
command = command_parser.parse

if command
  command.run
else
  command_parser.print_help_string
end
