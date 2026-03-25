require 'optparse'

def parse_arguments
  options = {
    recursive: false,
    depth: 5, 
    path: './data/',
    l_flag_provided: false # Un "chivato" para saber si el usuario usó -l explícitamente
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ./spider [-r] [-l N] [-p PATH] URL"

    opts.on('-r', 'Recursive download') do
      options[:recursive] = true
    end

    opts.on('-l N', Integer, 'Max depth (default: 5)') do |n|
      options[:depth] = n
      options[:l_flag_provided] = true
    end

    opts.on('-p PATH', String, 'Download path (default: ./data/)') do |p|
      options[:path] = p
    end

    opts.on('-h', '--help', 'Prints this help') do
      puts opts
      exit
    end
  end

  begin
    parser.parse!
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
    puts "Error: #{e.message}"
    puts parser
    exit 1
  end

  if ARGV.empty?
    puts "Error: Missing URL."
    puts parser
    exit 1
  end

  url = ARGV[0]

  if options[:depth] < 0
    puts "Error: depth must be >= 0"
    exit 1
  elsif options[:depth] > 8
    puts "Error: depth must be <= 8"
    exit 1
  end

  if options[:l_flag_provided] && !options[:recursive]
    puts "Error: The -l flag requires the -r flag"
    exit 1
  end

  return options, url
end
