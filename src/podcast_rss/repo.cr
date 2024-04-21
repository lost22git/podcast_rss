require "db"
require "duckdb"

module PodcastRss::Repo
  def self.connect(&)
    DB.connect "duckdb://./data.db" do |cnn|
      yield cnn
    end
  end

  def self.add_channel(channel : PodcastRss::Channel)
  end

  def self.update_channel(channel : PodcastRss::Channel)
  end

  def self.get_channel(channel_id : String) : PodcastRss::Channel | Nil
    nil
  end

  def self.get_channels : Array(PodcastRss::Channel)
    result = [] of PodcastRss::Channel
    result
  end

  def self.search_channels(q : String) : Array(PodcastRss::Channel)
    result = [] of PodcastRss::Channel
    result
  end

  def self.add_channel_items(channel_items : Array(PodcastRss::ChannelItem))
  end

  def self.get_last_channel_item(channel_id : String) : PodcastRss::ChannelItem | Nil
    nil
  end

  def self.get_latest_channel_items(channel_id : String, size : UInt32) : Array(PodcastRss::ChannelItem)
    result = [] of PodcastRss::ChannelItem
    result
  end
end
