class PodcastRss::Tasks
end

class PodcastRss::ChannelSyncTask
  def initialize(@channel)
  end

  def run
    last_channel_item = PodcastRss::Repo.get_last_channel_item(@channel.rss)

    # fetching
    rss_xml = PodcastRss.get_rss_xml_io(channel.rss)
    channel = PodcastRss.parse_channel rss_xml

    # saving
    PodcastRss.update_channel channel
    PodcastRss.add_channel_items(channel.items)
  end
end
