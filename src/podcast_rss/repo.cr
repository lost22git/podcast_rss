require "db"
require "duckdb"
require "./xid"

module PodcastRss::Repo
  def self.connect(&)
    DB.connect "duckdb://./data.db" do |cnn|
      yield cnn
    end
  end

  private def self.gen_id : ID
    XidGenerator.global.gen_id.to_s
  end

  STATIC_INIT_SQL = {{ read_file("#{__DIR__}/../../init.sql") }}

  private def self.load_init_sql : String
    # load order
    # 1. load from external init.sql file in executable_path dir
    # 2. load from internal init.sql file

    ex_init_sql_file = Process.executable_path.try { |p| Path.new(p).parent / "init.sql" }

    return STATIC_INIT_SQL unless ex_init_sql_file && File.exists?(ex_init_sql_file)

    File.read ex_init_sql_file
  end

  def self.exec_init_sql
    init_sql = self.load_init_sql

    Log.debug { "init_sql:\n#{init_sql}" }

    self.connect do |cnn|
      # can not exec sql scripts, so we split them
      init_sql.split(';', remove_empty: true) { |sql| cnn.exec sql unless sql.blank? }
    end
  end

  def self.add_channel(channel : PodcastRss::Channel)
    self.connect do |cnn|
      # TODO: RETURNING  id ?
      insert_sql = "
      INSERT INTO channel
        (id, rss, author, title, description, language, image)
      VALUES
        (?,?,?,?,?,?,?)
      "
      insert_args = [
        self.gen_id,
        channel.rss,
        channel.author,
        channel.title,
        channel.description,
        channel.language,
        channel.image,
      ]
      cnn.exec insert_sql, args: insert_args
    end
  end

  def self.delete_channel(channel_id : ID)
    self.connect do |cnn|
      delete_sql = "
      DELETE FROM channel
      WHERE
        id = ?
      "
      cnn.exec delete_sql, channel_id
    end
  end

  def self.update_channel(channel_id : ID, channel : PodcastRss::Channel)
    self.connect do |cnn|
      update_sql = "
      UPDATE channel
      SET
        rss = ?, title = ?, description = ?, author = ?, language = ?, image = ?
      WHERE
        id = ?
      "
      update_args = [
        channel.rss,
        channel.title,
        channel.description,
        channel.author,
        channel.language,
        channel.image,
        channel_id,
      ]
      cnn.exec update_sql, args: update_args
    end
  end

  def self.get_channel(channel_id : ID) : PodcastRss::Channel?
    result = nil
    self.connect do |cnn|
      select_sql = "
      SELECT
        id,rss,author,title,description,language,image
      FROM channel
      WHERE
        id=?
      "
      result = cnn.query_one?(select_sql, channel_id) { |rs| Channel.new rs }
    end
    result
  end

  def self.get_channels_by_rss(rss : String) : Array(PodcastRss::Channel)
    result = [] of Channel
    self.connect do |cnn|
      select_sql = "
      SELECT
        id,rss,author,title,description,language,image
      FROM channel
      WHERE
        rss=?
      "
      result = cnn.query_all(select_sql, rss) { |rs| Channel.new rs }
    end
    result
  end

  def self.get_channels : Array(PodcastRss::Channel)
    result = [] of Channel
    self.connect do |cnn|
      select_sql = "
      SELECT
        id,rss,title,description,author,language,image
      FROM channel
      "
      result = cnn.query_all(select_sql) { |rs| Channel.new rs }
    end
    result
  end

  def self.search_channels(q : String) : Array(PodcastRss::Channel)
    result = [] of Channel
    self.connect do |cnn|
      select_sql = "
      SELECT
        id,rss,title,description,author,language,image
      FROM channel
      WHERE
        author LIKE ? or title LIKE ? or description LIKE ?
      "
      result = cnn.query_all(select_sql, "%#{q}%", "%#{q}%", "%#{q}%") { |rs| Channel.new rs }
    end
    result
  end

  def self.add_channel_items(channel_id : ID, channel_items : Array(PodcastRss::ChannelItem))
    return unless channel_items.size > 0
    self.connect do |cnn|
      cnn.appender("channel_item") do |appender|
        channel_items.each do |item|
          appender.row do |row|
            row << self.gen_id
            row << channel_id
            row << item.title
            row << item.subtitle
            row << item.description
            row << item.pub_date
            row << item.image
            row << item.duration
            row << item.url
            row << item.type
            row << item.length
          end
        end
      end
    end
  end

  def self.delete_channel_item_by_channel_id(channel_id : ID)
    self.connect do |cnn|
      delete_sql = "
      DELETE FROM channel_item
      WHERE
        channel_id = ?
      "
      cnn.exec delete_sql, channel_id
    end
  end

  def self.get_last_channel_item(channel_id : ID) : PodcastRss::ChannelItem?
    result = nil
    self.connect do |cnn|
      select_sql = "
      SELECT
        id,channel_id,title,subtitle,description,pub_date,image,duration,url,type,length
      FROM channel_item
      WHERE
        channel_id = ?
      ORDER BY id DESC
      LIMIT 1
      "
      result = cnn.query_one?(select_sql, channel_id) { |rs| ChannelItem.new rs }
    end
    result
  end

  def self.get_latest_channel_items(channel_id : ID, size : UInt32) : Array(PodcastRss::ChannelItem)
    result = [] of ChannelItem
    self.connect do |cnn|
      select_sql = "
      SELECT
        id,channel_id,title,subtitle,description,pub_date,image,duration,url,type,length
      FROM channel_item
      WHERE
        channel_id = ?
      ORDER BY id DESC
      LIMIT ?
      "
      result = cnn.query_all(select_sql, channel_id, size) { |rs| ChannelItem.new rs }
    end
    result
  end

  def self.get_channel_item(channel_item_id : ID) : PodcastRss::ChannelItem?
    result = nil
    self.connect do |cnn|
      select_sql = "
      SELECT
        id,channel_id,title,subtitle,description,pub_date,image,duration,url,type,length
      FROM channel_item
      WHERE
        id = ?
      "
      result = cnn.query_one?(select_sql, channel_item_id) { |rs| ChannelItem.new rs }
    end
    result
  end
end
