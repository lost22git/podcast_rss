require "xml"

class PodcastRss::XmlTool
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
      break unless reader.read
      node_type = reader.node_type
      break unless node_type.cdata? || node_type.text?
      result << reader.value
    end
    result.to_s
  end
end
