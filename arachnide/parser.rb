require 'optparse'

def parse_arguments
  
  options = {
    recursive: false,
    depth: 5,
    path: './data/'
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ./spider [-r] [-l N] [-p PATH] URL"

    opts.on('-r', 'Recursive download') do
      options[:recursive] = true
    end

    opts.on('-l N', Integer, 'Max depth (default: 5)') do |n|
      options[:depth] = n
    end

    opts.on('-p PATH', String, 'Download path (default: ./data/)') do |p|
      options[:path] = p
    end
  end

  parser.parse!

  if ARGV.empty?
    puts parser
    exit 1
  end

  url = ARGV[-1]

  if options[:depth] < 0
    puts "Error: depth must be >= 0"
    exit 1
  elsif options[:depth] > 8
    puts "Error: depth must be <= 8"
  end

  if options[:depth] != 5 && !options[:recursive]
    puts "Error: -l requires -r"
    exit 1
  end

  return options, url
end
