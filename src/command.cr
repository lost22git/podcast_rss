require "./podcast_rss"

require "option_parser"

abstract class PodcastRss::Command
  abstract def run
end

class PodcastRss::ListCommand < PodcastRss::Command
  def initialize
  end

  def run
    PodcastRss.get_channels.each do |channel|
      channel.items = PodcastRss.get_latest_channel_items channel.id
      channel.print
    end
  end
end

class PodcastRss::AddCommand < PodcastRss::Command
  def initialize(@rss : String)
  end

  def run
    if @rss.blank?
      Log.error { "Requires RSS is not blank" }
    else
      PodcastRss.add_rss @rss
    end
  end
end

class PodcastRss::SyncCommand < PodcastRss::Command
  def initialize(@channel_id : ID?)
  end

  def run
    if v = @channel_id
      PodcastRss.sync_channel v
    else
      PodcastRss.sync_all_channels
    end
  end
end

class PodcastRss::DelCommand < PodcastRss::Command
  def initialize(@channel_id : ID)
  end

  def run
    PodcastRss.delete_channel @channel_id
  end
end

class PodcastRss::ShellCommand < PodcastRss::Command
  def initialize
  end

  def run
    shell_path = Process.executable_path.try { |p| Path.new(p).parent / "podcast_rss_shell" }
    if cmd = shell_path
      Process.exec cmd.to_s if File.exists?(cmd)
    else
      Process.exec "podcast_rss_shell"
    end
  end
end

class PodcastRss::VersionCommand < PodcastRss::Command
  def initialize
  end

  def run
    puts PodcastRss::VERSION
  end
end

class PodcastRss::CommandParser
  @parser : OptionParser
  @command : Command? = nil

  def initialize
    @parser = OptionParser.new do |parser|
      parser.banner = usage_text "podcast_rss [arguments]"
      parser.on("ls", "List channels") do
        parser.banner = usage_text "podcast_rss list"
        @command = ListCommand.new
      end
      parser.on("add", "Add channel by rss") do
        parser.banner = usage_text "podcast_rss add --rss <RSS>"
        parser.on("--rss <RSS>", "Specify rss to add channel") do |_rss|
          @command = AddCommand.new _rss
        end
      end
      parser.on("sync", "Sync channels news") do
        parser.banner = usage_text "podcast_rss sync [--channel <CHANNEL_ID>]"
        parser.on("--channel <CHANNEL_ID>", "Specify channel id to sync news (Optional: default sync all channel)") do |_channel_id|
          @command = SyncCommand.new _channel_id
        end
        @command = SyncCommand.new nil
      end
      parser.on("del", "Delete channel") do
        parser.banner = usage_text "podcast_rss del --channel <CHANNEL_ID>"
        parser.on("--channel <CHANNEL_ID>", "Specify channel id to delete") do |_channel_id|
          @command = DelCommand.new _channel_id
        end
      end
      parser.on("shell", "Enter iteractive shell") do
        parser.banner = usage_text "podcast_rss shell"
        @command = ShellCommand.new
      end
      parser.on("version", "Show this version") do
        @command = VersionCommand.new
      end
      parser.on("-V", "--version", "Show this version") do
        @command = VersionCommand.new
      end
      parser.on("help", "Show this help") do
        puts parser
      end
      parser.on("-h", "--help", "Show this help") do
        puts parser
      end
      parser.invalid_option do |_option|
        puts "invalid option `#{_option}`"
        puts parser
      end
      parser.missing_option do |_option|
        puts "missing option `#{_option}`"
        puts parser
      end
    end
  end

  def print_help_string
    puts @parser
  end

  private def usage_text(text : String) : String
    "\nUsage:\n    #{text}\n"
  end

  def parse(cmdline_argv : Array(String) = ARGV) : PodcastRss::Command?
    @command = nil
    @parser.parse cmdline_argv
    @command
  end
end
