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
    Channel.from_xml reader, need_stop_parsing
  end

  def self.add_rss(rss_link : String)
    channel = Channel.new
    channel.rss = rss_link
    Repo.add_channel channel
  end

  def self.sync_channel(channel_id : ID)
    channel = Repo.get_channel channel_id
    if channel
      channel_sync_task = ChannelSyncTask.new channel
      channel_sync_task.run
    else
      Log.error { "channel not found, channel: #{channel_id}" }
    end
  end

  def self.sync_all_channels
    channels = Repo.get_channels
    return unless channels.size > 0
    waiter = ::Channel(Nil).new
    channels.each { |channel| self.spawn_sync_channel channel, waiter }
    (1..channels.size).each { |i| waiter.receive }
  end

  private def self.spawn_sync_channel(channel : PodcastRss::Channel, waiter : ::Channel(Nil))
    spawn do
      begin
        channel_sync_task = ChannelSyncTask.new channel
        channel_sync_task.run
      ensure
        waiter.send nil
      end
    end
  end

  def self.get_channels : Array(PodcastRss::Channel)
    Repo.get_channels
  end

  def self.search_channels(q : String) : Array(PodcastRss::Channel)
    Repo.search_channels q
  end

  def self.get_latest_channel_items(channel_id : ID, size : UInt32 = 6) : Array(PodcastRss::ChannelItem)
    Repo.get_latest_channel_items channel_id, size
  end
end
