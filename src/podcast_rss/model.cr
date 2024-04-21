require "xml"

class PodcastRss::Channel
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
          PodcastRss::XmlTool.parse_element reader, "channel", result do |reader, element_name, into|
            {% begin %}
              case element_name
              when .=~ /^item$/i
                into.items << PodcastRss::ChannelItem.from_xml(reader)

              {% for p in %w{title description language itunes:author} %}
              when .=~ /^{{ p.id }}$/i
                {% id = p.split(":").last.id %}
                {{ id }} = PodcastRss::XmlTool.read_inner_text reader
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

class PodcastRss::ChannelItem
  {% for p in %w{title subtittle description image pubDate duration} %}
    property {{ p.id }} : String = ""
    {% end %}

  property audio : ChannelAudio = ChannelAudio.new

  def initialize
  end

  def self.from_xml(reader : XML::Reader)
    result = PodcastRss::ChannelItem.new
    PodcastRss::XmlTool.parse_element reader, "item", result do |reader, element_name, into|
      {% begin %}
        case element_name
        {% for p in %w{title description pubDate itunes:subtittle itunes:duration} %}
        when .=~ /^{{ p.id }}$/i
          {% id = p.split(":").last.id %}
          {{ id }} = PodcastRss::XmlTool.read_inner_text reader
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

class PodcastRss::ChannelAudio
  {% for p in %w{url type length} %}
    property {{ p.id }} : String = ""
    {% end %}

  def initialize
  end
end
