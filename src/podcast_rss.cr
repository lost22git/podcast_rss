require "log"
require "http/client"
require "xml"
require "./podcast_rss/**"

# Logging configuartion
#
Log.setup do |config|
  console = Log::IOBackend.new
  {% if flag?(:release) %}
    config.bind "*", :info, console
  {% else %}
    config.bind "*", :debug, console
  {% end %}
end

module PodcastRss
  def self.get_rss_xml(rss_link : String) : String
    resp = HTTP::Client.get rss_link
    resp.body
  end

  def self.get_rss_xml_io(rss_link : String, & : IO ->)
    HTTP::Client.get rss_link do |resp|
      yield resp.body_io
    end
  end

  def self.parse_channel(rss_xml : String | IO, need_stop_parsing : Proc(PodcastRss::Channel, Bool) = PodcastRss::Channel::NEVER_STOP_PARSING) : PodcastRss::Channel
    reader = XML::Reader.new rss_xml
    PodcastRss::Channel.from_xml reader, need_stop_parsing
  end

  def self.add_rss(rss_link : String)
    channel = PodcastRss::Channel.new
    channel.rss = rss_link
    PodcastRss::Repo.add_channel channel
  end

  def self.sync_channel(channel_id : String)
    channel = PodcastRss::Repo.get_channel channel_id
    if channel
      channel_sync_task = PodcastRss::ChannelSyncTask.new channel
      channel_sync_task.run
    else
      Log.error { "channel not found, channel: #{channel_id}" }
    end
  end

  def self.sync_all_channels
    # TODO: parallelize
    channels = PodcastRss::Repo.get_channels
    channels.each do |channel|
      channel_sync_task = PodcastRss::ChannelSyncTask.new channel
      channel_sync_task.run
    end
  end

  def self.get_channels : Array(PodcastRss::Channel)
    PodcastRss::Repo.get_channels
  end

  def self.search_channels(q : String) : Array(PodcastRss::Channel)
    PodcastRss::Repo.search_channels q
  end

  def self.get_latest_channel_items(channel_id : String, size : UInt32) : Array(PodcastRss::ChannelItem)
    PodcastRss::Repo.get_latest_channel_items channel_id, size
  end
end

rss_list = [
  "http://rss.lizhi.fm/rss/14275.xml",
  "http://www.ximalaya.com/album/4494083.xml",
  "https://s1.proxy.wavpub.com/storyhunting.xml",
]

rss_list.each do |rss_link|
  PodcastRss.get_rss_xml_io(rss_link) do |rss_xml|
    channel = PodcastRss.parse_channel rss_xml
    channel.print
  end
end
