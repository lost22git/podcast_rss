require "xml"

require "db"

alias ID = String

class PodcastRss::Channel
  include DB::Serializable

  {% for p in %w{rss author title description language image} %}
    property {{ p.id }} : String = ""
  {% end %}

  property id : ID = ""

  @[DB::Field(ignore: true)]
  property items : Array(ChannelItem) = [] of ChannelItem

  def initialize
  end

  NEVER_STOP_PARSING = ->(channel : PodcastRss::Channel) { false }

  def self.from_xml(reader : XML::Reader, need_stop_parsing : Proc(PodcastRss::Channel, Bool) = NEVER_STOP_PARSING)
    result = Channel.new
    while true
      break unless reader.read
      case reader.node_type
      when .element?
        if reader.name =~ /^channel$/i
          XmlTool.parse_element reader, "channel", result do |reader, element_name, into|
            {% begin %}
              case element_name
              when .=~ /^item$/i
                channel_item = ChannelItem.from_xml(reader)
                into.items << channel_item
                break if need_stop_parsing.call(into)

              {% for p in %w{title description language itunes:author} %}
              when .=~ /^{{ p.id }}$/i
                {% id = p.split(":").last.id %}
                {{ id }} = XmlTool.read_inner_text reader
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
    puts "id".ljust(10) + " : " + self.id.to_s
    puts "channel".ljust(10) + " : " + self.title
    puts "author".ljust(10) + " : " + self.author
    puts "episodes".ljust(10) + " : " + self.items.size.to_s
    puts "-" * 88
    (0..5).each do |i|
      item = self.items[i]
      puts "title".rjust(15) + " : " + osc8_hyperlink(item.title, item.url)
      puts "pubDate".rjust(15) + " : " + item.pubDate
      puts "duration".rjust(15) + " : " + item.duration
    end
  end
end

class PodcastRss::ChannelItem
  include DB::Serializable

  {% for p in %w{title subtitle description image pubDate duration url type length} %}
    property {{ p.id }} : String = ""
  {% end %}

  property id : ID = ""
  property channel_id : ID = ""

  def initialize
  end

  def self.from_xml(reader : XML::Reader)
    result = ChannelItem.new
    XmlTool.parse_element reader, "item", result do |reader, element_name, into|
      {% begin %}
        case element_name
        {% for p in %w{title description pubDate itunes:subtitle itunes:duration} %}
        when .=~ /^{{ p.id }}$/i
          {% id = p.split(":").last.id %}
          {{ id }} = XmlTool.read_inner_text reader
          into.{{ id }} = {{ id }}
        {% end %}

        when .=~ /^itunes:image$/i
          image = reader["href"] || ""
          into.image = image

        when .=~ /^enclosure$/i
          {% for p in %w{url type length} %}
          {{ p.id }} = reader[{{ p }}]? || ""
          into.{{ p.id }} = {{ p.id }}
          {% end %}
        end
        {% end %}
    end
    result
  end
end
