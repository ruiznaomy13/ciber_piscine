#d frozen_string_literal: true

require 'set'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'fileutils'
require_relative "command"

MAX_PGS = 8
EXT = %w[.jpg .jpeg .png .bmp]

class Spider < Command
  desc "./spider [-rlp] URL", "Extract all images from a website recursively."

  option(:recursive, aliases: ["-r"], type: :boolean, desc: "Recursively download images")
  option(:level, aliases: ["-l"], type: :numeric, default: 5, desc: "Maximum recursion depth", requires: :recursive)
  option(:path, aliases: ["-p"], type: :string, default: "./data/", desc: "Download path")

  argument(:url, required: true, banner: "URL")

  def pre_msgs(url)
    say("Spider Image Extractor", :cyan, :bold)
    say("-----------------------", :magenta)
    say("Target:    #{url}", :cyan)
    say("Path:      #{options[:path]}", :cyan)
    say("Recursive: #{options[:recursive] ? "Yes" : "No"}", :cyan)

    say("Max Depth: #{options[:level]}", :cyan) if options[:recursive]

    say("\n\t[ Connecting to #{url}...]\n\n", :magenta, :bold)
  end

  def safe_fetch(url)
    uri = URI(url)

    return nil unless uri.is_a?(URI::Generic) && uri.scheme =~ /^https?$/

    Net::HTTP.get(uri)
  rescue 
      nil
  end

  def normalize_url(url)
    URI.parse(URI::DEFAULT_PARSER.escape(url))
  rescue
    nil
  end

  def download_img(doc, url, options, saved_imgs = Set.new)
    images = doc.css('img').map do |img|
      src = img['src']
      next unless src 

      begin
        absolute = URI.join(url, src)
        normalized = normalize_url(absolute.to_s)
        normalized.to_s if normalized
      rescue
        say("WARNING: url failed to be normalized", :yellow, :bold)
        nil
      end
    end.compact

    FileUtils.mkdir_p(options[:path])

    images.each do |img_url|
      next if saved_imgs.include?(img_url)
      saved_imgs.add(img_url)

      begin
        img_uri = URI(img_url)
        filename = File.basename(img_uri.path)
        ext = File.extname(filename).downcase

        next unless EXT.include?(ext)

        unique_filename = "#{Time.now.to_i}_#{rand(1000)}_#{filename}"
        filepath = File.join(options[:path], unique_filename)

        Net::HTTP.start(img_uri.host, img_uri.port, use_ssl: img_uri.scheme == 'https') do |http|
          request_path = img_uri.request_uri || '/'
          response = http.get(request_path)
          File.open(filepath, 'wb') { |file| file.write(response.body) }
        end

        print "#{img_url}"
        say("\t[saved]\n", :green)
      rescue => e
        say("WARNING: download failed for #{img_url}: #{e.message}", :yellow)
      end
    end
  end

  def recursion(url, options, current_depth = 0, visited = Set.new, saved_imgs = Set.new)
    return if current_depth > options[:level]
    return if visited.size >= MAX_PGS
    return if visited.include?(url)

    visited.add(url)
    say "Depth #{current_depth}: #{url}", :blue

    html = safe_fetch(url)
    return say("WARNING: Failed to fetch URL: #{url}", :yellow) unless html

    doc = Nokogiri::HTML(html)

    download_img(doc, url, options, saved_imgs)

    return if current_depth == options[:level]

    links = doc.css('a').map do |a|
      href = a['href']
      next unless href

      begin
        URI.join(url, href).to_s
      rescue
        nil
      end
    end.compact

    links.each do |link|
      recursion(link, options, current_depth + 1, visited, saved_imgs)
    end
  end

  def perform(args)
    url = args.first
    
    pre_msgs(url)

    if options[:recursive]
      recursion(url, options)
    else
      html = safe_fetch(url)
      return say("WARNING: Failed to fetch URL: #{url}", :yellow) unless html

      doc = Nokogiri::HTML(html)
      download_img(doc, url, options)
    end
  end
end
