require "db"
require "duckdb"
require "snowflake"

module PodcastRss::Repo
  def self.connect(&)
    DB.connect "duckdb://./data.db" do |cnn|
      yield cnn
    end
  end

  STATIC_INIT_SQL = {{ read_file("#{__DIR__}/../../init.sql") }}

  ID_GENERATOR = Snowflake.new(1_u64)

  private def self.gen_id : ID
    ID_GENERATOR.generate_id.to_s
  end

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
      # can not exec multi sqls, so we split them
      init_sql.split(';', remove_empty: true) do |sql|
        cnn.exec sql unless sql.blank?
      end
    end
  end

  def self.add_channel(channel : PodcastRss::Channel)
    self.connect do |cnn|
      # TODO: RETURNING  id ?
      insert_sql = "
      insert into channel
      (id, rss, author, title, description, language, image)
      values (?,?,?,?,?,?,?)
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

  def self.update_channel(channel_id : ID, channel : PodcastRss::Channel)
    self.connect do |cnn|
      update_sql = "
      update channel
      set rss = ?, title = ?, description = ?, author = ?, language = ?, image = ?
      where id = ?
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
      select id,rss,author,title,description,language,image
      from channel
      where id=?
      "
      result = cnn.query_one? select_sql, channel_id do |rs|
        channel = Channel.new
        channel.id = rs.read(ID)
        channel.rss = rs.read(String)
        channel.author = rs.read(String)
        channel.title = rs.read(String)
        channel.description = rs.read(String)
        channel.language = rs.read(String)
        channel.image = rs.read(String)
        channel
      end
    end
    result
  end

  def self.get_channels : Array(PodcastRss::Channel)
    result = [] of Channel
    self.connect do |cnn|
      select_sql = "
      select id,rss,title,description,author,language,image from channel
      "
      result = cnn.query_all select_sql do |rs|
        channel = Channel.new
        channel.id = rs.read(ID)
        channel.rss = rs.read(String)
        channel.title = rs.read(String)
        channel.description = rs.read(String)
        channel.author = rs.read(String)
        channel.language = rs.read(String)
        channel.image = rs.read(String)
        channel
      end
    end
    result
  end

  def self.search_channels(q : String) : Array(PodcastRss::Channel)
    result = [] of Channel
    self.connect do |cnn|
      select_sql = "
      select id,rss,title,description,author,language,image
      from channel
      where author like ? or title like ? or description like ?
      "
      result = cnn.query_all select_sql, "%#{q}%", "%#{q}%", "%#{q}%" do |rs|
        channel = Channel.new
        channel.id = rs.read(ID)
        channel.rss = rs.read(String)
        channel.title = rs.read(String)
        channel.description = rs.read(String)
        channel.author = rs.read(String)
        channel.language = rs.read(String)
        channel.image = rs.read(String)
        channel
      end
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

  def self.get_last_channel_item(channel_id : ID) : PodcastRss::ChannelItem?
    result = nil
    self.connect do |cnn|
      select_sql = "
      select id,channel_id,title,subtitle,description,image,duration,url,type,length
      from channel_item
      where channel_id = ? order by id desc limit 1
      "
      result = cnn.query_one? select_sql, channel_id do |rs|
        channel_item = ChannelItem.new
        channel_item.id = rs.read(ID)
        channel_item.channel_id = rs.read(ID)
        channel_item.title = rs.read(String)
        channel_item.subtitle = rs.read(String)
        channel_item.description = rs.read(String)
        channel_item.image = rs.read(String)
        channel_item.duration = rs.read(String)
        channel_item.url = rs.read(String)
        channel_item.type = rs.read(String)
        channel_item.length = rs.read(String)
        channel_item
      end
    end
    result
  end

  def self.get_latest_channel_items(channel_id : ID, size : UInt32) : Array(PodcastRss::ChannelItem)
    result = [] of ChannelItem
    self.connect do |cnn|
      select_sql = "
      select id,channel_id,title,subtitle,description,image,duration,url,type,length
      from channel_item
      where channel_id = ?
      order by id desc limit ?
      "
      result = cnn.query_all select_sql, channel_id, size do |rs|
        channel_item = ChannelItem.new
        channel_item.id = rs.read(ID)
        channel_item.channel_id = rs.read(ID)
        channel_item.title = rs.read(String)
        channel_item.subtitle = rs.read(String)
        channel_item.description = rs.read(String)
        channel_item.image = rs.read(String)
        channel_item.duration = rs.read(String)
        channel_item.url = rs.read(String)
        channel_item.type = rs.read(String)
        channel_item.length = rs.read(String)
        channel_item
      end
    end
    result
  end
end
