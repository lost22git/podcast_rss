require "log"
require "http/client"
require "xml"
require "./podcast_rss/**"

# Logging configuartion
#
Log.setup do |config|
  console = Log::IOBackend.new dispatcher: Log::DispatchMode::Sync
  {% if flag?(:release) %}
    config.bind "*", :info, console
  {% else %}
    config.bind "*", :debug, console
  {% end %}
end

module PodcastRss
  def self.get_rss_xml(rss : String) : String
    resp = HTTP::Client.get rss
    resp.body
  end

  def self.get_rss_xml_io(rss : String, & : IO ->)
    HTTP::Client.get rss do |resp|
      yield resp.body_io
    end
  end

  def self.parse_channel(rss_xml : String | IO, need_stop_parsing : Proc(PodcastRss::Channel, Bool) = PodcastRss::Channel::NEVER_STOP_PARSING) : PodcastRss::Channel
    reader = XML::Reader.new rss_xml
    Channel.from_xml reader, need_stop_parsing
  end

  def self.add_rss(rss : String)
    unless Repo.get_channels_by_rss(rss.strip).empty?
      Log.error { "channel exists" }
      return
    end
    channel = Channel.new
    channel.rss = rss.strip
    Repo.add_channel channel
    Log.info { "a channel added" }
  end

  def self.delete_channel(channel_id : ID)
    Repo.delete_channel_item_by_channel_id channel_id
    Repo.delete_channel channel_id
    Log.info { "a channel deleted" }
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
