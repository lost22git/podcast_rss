require "./spec_helper"

describe PodcastRss do
  # TODO: Write tests

  it "works" do
    true.should eq(true)
  end

  it "duckdb connect successfully" do
    PodcastRss::Repo.connect do |cnn|
      p! cnn.scalar "select 1"
    end
  end

  it "sync channel" do
    PodcastRss::Repo.exec_init_sql

    rss_list = [
      "http://rss.lizhi.fm/rss/14275.xml",
    ]

    # add rss
    rss_list.each do |rss_link|
      PodcastRss.add_rss rss_link
    end

    # assert
    PodcastRss.get_channels.each do |channel|
      channel.rss.should eq rss_list[0]

      channel.items = PodcastRss.get_latest_channel_items channel.id

      channel.items.should be_empty
    end

    # sync
    PodcastRss.sync_all_channels

    last_channel_item = nil

    # assert
    PodcastRss.get_channels.each do |channel|
      channel.rss.should eq rss_list[0]
      channel.title.should_not eq ""

      channel.items = PodcastRss.get_latest_channel_items channel.id

      channel.items.should_not be_empty

      last_channel_item = channel.items[0]
    end

    # sync again
    PodcastRss.sync_all_channels

    # assert
    PodcastRss.get_channels.each do |channel|
      channel.rss.should eq rss_list[0]

      channel.items = PodcastRss.get_latest_channel_items channel.id

      channel.items.should_not be_empty

      channel.items[0].title.should eq last_channel_item.not_nil!.title
    end
  end
end
