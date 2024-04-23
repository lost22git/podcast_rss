require "./podcast_rss"

require "option_parser"

# PodcastRss::Repo.exec_init_sql

# rss_list = [
#   "http://rss.lizhi.fm/rss/14275.xml",
#   "http://www.ximalaya.com/album/4494083.xml",
#   "https://s1.proxy.wavpub.com/storyhunting.xml",
# ]

abstract class PodcastRss::Command
  abstract def run
end

class PodcastRss::ListCommand < PodcastRss::Command
  def initialize
  end

  def run
    PodcastRss.get_channels.each do |channel|
      channel.items = PodcastRss.get_latest_channel_items channel.id
      channel.print
    end
  end
end

class PodcastRss::AddCommand < PodcastRss::Command
  def initialize(@rss : String)
  end

  def run
    if @rss.blank?
      Log.error { "Requires RSS is not blank" }
    else
      PodcastRss.add_rss @rss
    end
  end
end

class PodcastRss::SyncCommand < PodcastRss::Command
  def initialize(@channel_id : ID?)
  end

  def run
    if v = @channel_id
      PodcastRss.sync_channel v
    else
      PodcastRss.sync_all_channels
    end
  end
end

class PodcastRss::DelCommand < PodcastRss::Command
  def initialize(@channel_id : ID)
  end

  def run
    PodcastRss.delete_channel @channel_id
  end
end

command : PodcastRss::Command? = nil

parser = OptionParser.new do |parser|
  parser.banner = "Usage: podcast_rss [subcommand] [arguments]"
  parser.on("list", "List channels") do
    parser.banner = "Usage: podcast_rss list"
    command = PodcastRss::ListCommand.new
  end
  parser.on("add", "Add channel by rss") do
    parser.banner = "Usage: podcast_rss add --rss <rss>"
    parser.on("--rss RSS", "Specify rss to add channel") do |_rss|
      command = PodcastRss::AddCommand.new _rss
    end
  end
  parser.on("sync", "Sync channels news") do
    parser.banner = "Usage: podcast_rss sync [--channel channel_id]"
    parser.on("--channel CHANNEL_ID", "Specify channel id to sync news (Optional: default sync all channel)") do |_channel_id|
      command = PodcastRss::SyncCommand.new _channel_id
    end
    command = PodcastRss::SyncCommand.new nil
  end
  parser.on("del", "Delete channel") do
    parser.banner = "Usage: podcast_rss del [--channel channel_id]"
    parser.on("--channel CHANNEL_ID", "Specify channel id to delete") do |_channel_id|
      command = PodcastRss::DelCommand.new _channel_id
    end
  end
  parser.on("-V", "--version", "Show this version") do
    puts PodcastRss::VERSION
    exit
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end

parser.parse

if c = command
  c.run
end
