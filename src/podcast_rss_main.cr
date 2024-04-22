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
