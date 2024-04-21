class PodcastRss::Tasks
end

class PodcastRss::ChannelSyncTask
  def initialize(@channel)
  end

  def run
    last_channel_item = PodcastRss::Repo.get_last_channel_item(@channel.rss)

    # fetching
    fetch_channel_by last_channel_item

    # saving
    PodcastRss.update_channel channel
    PodcastRss.add_channel_items(channel.items)
  end

  def fetch_channel_by(last_channel_item : PodcastRss::ChannelItem | Nil) : PodcastRss::Channel
    rss_xml = PodcastRss.get_rss_xml_io(channel.rss)
    if last_channel_item
      # parsing incremental items
      PodcastRss.parse_channel rss_xml do |channel|
        need_stop = (channel.items.last.title == last_channel_item.title)
        channel.items.remove_last if need_stop
        need_stop
      end
    else
      # parsing all items
      PodcastRss.parse_channel rss_xml
    end
  end
end
