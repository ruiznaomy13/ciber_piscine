require 'set'
require 'uri'
require 'net/http'
require 'nokogiri'
require 'fileutils'
require_relative 'parser'

EXT = %w[.jpg .jpeg .png .gif .bmp]
MAX_PGS = 10

def safe_fetch(url)
  uri = URI(url)

  return nil unless uri.is_a?(URI::HTTP)

  Net::HTTP.get(uri)
rescue
  nil
end

def normalize_url(url)
  URI.parse(URI::DEFAULT_PARSER.escape(url))
rescue
  nil
end


def download_img(doc, url, options, saved_imgs)
  images = doc.css('img').map do |img|
    src = img['src']
    next unless src # Skip if img tag has no src

    begin
      absolute = URI.join(url, src)
      normalized = normalize_url(absolute.to_s)
      normalized.to_s if normalized
    rescue
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

      # Prevent file overwrites by adding a short unique identifier
      unique_filename = "#{Time.now.to_i}_#{rand(1000)}_#{filename}"
      filepath = File.join(options[:path], unique_filename)

      Net::HTTP.start(img_uri.host, img_uri.port, use_ssl: img_uri.scheme == 'https') do |http|
        # Use request_uri to keep query parameters (e.g., ?v=123)
        request_path = img_uri.request_uri || '/'
        response = http.get(request_path)
        File.open(filepath, 'wb') { |file| file.write(response.body) }
      end

      puts "#{img_url} SUCCESSFULLY SAVED! :)\n"
    rescue => e
      puts "DOWNLOAD FAILED for #{img_url}: #{e.message}"
    end
  end
end
