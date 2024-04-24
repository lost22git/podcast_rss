require "./command"

require "fancyline"

fancy = Fancyline.new
puts "Press Ctrl-C or Ctrl-D to quit."

fancy.display.add do |ctx, line, yielder|
  # We underline command names
  line = line.gsub(/^\w+/, &.colorize.mode(:underline))
  line = line.gsub(/(\|\s*)(\w+)/) do
    "#{$1}#{$2.colorize.mode(:underline)}"
  end

  # And turn --arguments green
  line = line.gsub(/--?\w+/, &.colorize(:green))

  # Then we call the next middleware with the modified line
  yielder.call ctx, line
end

command_parser = PodcastRss::CommandParser.new

begin
  while input = fancy.readline("podcast_rss> ")
    command_argv = ["podcast_rss"] + input.split(' ', remove_empty: true)
    command = command_parser.parse command_argv
    if cmd = command
      cmd.run
    else
      command_parser.print_help_string
    end
  end
rescue err : Fancyline::Interrupt
  puts "Bye."
end
