class PodcastRss::Tasks
end

class PodcastRss::ChannelSyncTask
  def initialize(@channel : Channel)
  end

  def run
    Log.info { "syncing channel: [#{@channel.title}] from (#{@channel.rss})" }

    last_channel_item = Repo.get_last_channel_item(@channel.id)

    # fetching
    channel = fetch_channel_by last_channel_item
    channel.rss = @channel.rss

    # saving
    Repo.update_channel @channel.id, channel
    Repo.add_channel_items @channel.id, channel.items.reverse

    Log.info { "sync ok, channel: [#{channel.title}] add (#{channel.items.size}) items" }
  end

  def fetch_channel_by(last_channel_item : PodcastRss::ChannelItem?) : PodcastRss::Channel
    result = Channel.new
    PodcastRss.get_rss_xml_io(@channel.rss) do |rss_xml|
      if last_channel_item
        need_stop_parsing = ->(channel : Channel) {
          need_stop = (channel.items.last.title == last_channel_item.title)
          channel.items.pop if need_stop
          need_stop
        }
        # parsing incremental items
        result = PodcastRss.parse_channel rss_xml, need_stop_parsing
      else
        # parsing all items
        result = PodcastRss.parse_channel rss_xml
      end
    end
    result
  end
end
