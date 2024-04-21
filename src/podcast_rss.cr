require "http/client"
require "xml"

module PodcastRss
  class Channel
    {% for p in %w{rss author title description language image} %}
    property {{ p.id }} : String = ""
    {% end %}

    property items : Array(ChannelItem) = [] of ChannelItem

    def initialize
    end

    def self.from_xml(reader : XML::Reader)
      result = PodcastRss::Channel.new
      while true
        break unless reader.read
        case reader.node_type
        when .element?
          if reader.name =~ /^channel$/i
            PodcastRss.parse_element reader, "channel", result do |reader, element_name, into|
              {% begin %}
              case element_name
              when .=~ /^item$/i
                into.items << PodcastRss::ChannelItem.from_xml(reader)

              {% for p in %w{title description language itunes:author} %}
              when .=~ /^{{ p.id }}$/i
                {% id = p.split(":").last.id %}
                {{ id }} = PodcastRss.read_inner_text reader
                into.{{ id }} = {{ id }}
              {% end %}

              when .=~ /^itunes:image$/i
                image = reader["href"] || ""
                into.image = image
              end
              {% end %}
            end
          end
        end
      end
      result
    end

    private def osc8_hyperlink(title, url : String) : String
      "\e]8;;" + url + "\e\\" + title + "\e]8;;" + "\e\\"
    end

    def print
      puts "-" * 88
      puts "channel".ljust(10) + " : " + self.title
      puts "author".ljust(10) + " : " + self.author
      puts "episodes".ljust(10) + " : " + self.items.size.to_s
      puts "-" * 88
      (0..5).each do |i|
        item = self.items[i]
        puts "title".rjust(15) + " : " + osc8_hyperlink(item.title, item.audio.url)
        puts "pubDate".rjust(15) + " : " + item.pubDate
        puts "duration".rjust(15) + " : " + item.duration
      end
    end
  end

  class ChannelItem
    {% for p in %w{title subtittle description image pubDate duration} %}
    property {{ p.id }} : String = ""
    {% end %}

    property audio : ChannelAudio = ChannelAudio.new

    def initialize
    end

    def self.from_xml(reader : XML::Reader)
      result = PodcastRss::ChannelItem.new
      PodcastRss.parse_element reader, "item", result do |reader, element_name, into|
        {% begin %}
        case element_name
        {% for p in %w{title description pubDate itunes:subtittle itunes:duration} %}
        when .=~ /^{{ p.id }}$/i
          {% id = p.split(":").last.id %}
          {{ id }} = PodcastRss.read_inner_text reader
          into.{{ id }} = {{ id }}
        {% end %}

        when .=~ /^itunes:image$/i
          image = reader["href"] || ""
          into.image = image

        when .=~ /^enclosure$/i
          {% for p in %w{url type length} %}
          {{ p.id }} = reader[{{ p }}]? || ""
          into.audio.{{ p.id }} = {{ p.id }}
          {% end %}
        end
        {% end %}
      end
      result
    end
  end

  class ChannelAudio
    {% for p in %w{url type length} %}
    property {{ p.id }} : String = ""
    {% end %}

    def initialize
    end
  end

  def self.get_rss_xml(rss_link : String) : String
    resp = HTTP::Client.get rss_link
    resp.body
  end

  def self.get_rss_xml_io(rss_link : String, & : IO ->)
    HTTP::Client.get rss_link do |resp|
      yield resp.body_io
    end
  end

  def self.parse_channel(rss_xml : String | IO) : PodcastRss::Channel
    reader = XML::Reader.new rss_xml
    PodcastRss::Channel.from_xml reader
  end

  def self.parse_element(reader : XML::Reader, element_name : String, into : T, &) forall T
    while true
      raise "missing </#{element_name}> before EOF" unless reader.read
      case reader.node_type
      when .end_element?
        return if reader.name =~ Regex.literal(element_name, i: true)
      when .element?
        yield reader, reader.name, into
      end
    end
  end

  def self.read_inner_text(reader : XML::Reader) : String
    result = String::Builder.new ""
    while true
      return "" unless reader.read
      node_type = reader.node_type
      break unless node_type.cdata? || node_type.text?
      result << reader.value
    end
    result.to_s
  end
end

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
