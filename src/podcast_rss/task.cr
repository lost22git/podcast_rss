class PodcastRss::Tasks
end

class PodcastRss::ChannelSyncTask
  def initialize(@channel : PodcastRss::Channel)
  end

  def run
    Log.info { "syncing channel: [#{@channel.title}] from (#{@channel.rss})" }

    last_channel_item = PodcastRss::Repo.get_last_channel_item(@channel.rss)

    # fetching
    channel = fetch_channel_by last_channel_item

    # saving
    PodcastRss::Repo.update_channel channel
    PodcastRss::Repo.add_channel_items channel.items

    Log.info { "sync ok, channel: [#{channel.title}] add (#{channel.items.size}) items" }
  end

  def fetch_channel_by(last_channel_item : PodcastRss::ChannelItem | Nil) : PodcastRss::Channel
    result = PodcastRss::Channel.new
    PodcastRss.get_rss_xml_io(@channel.rss) do |rss_xml|
      if last_channel_item
        need_stop_parsing = ->(channel : PodcastRss::Channel) {
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
