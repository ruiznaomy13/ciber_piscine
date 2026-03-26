#d frozen_string_literal: true

require 'exifr/jpeg'
require_relative "command"

VALID_EXT = [".jpg", ".jpeg", ".png", ".bmp", ".gif"]

class Scorpion < Command
  desc "./scorpion FILE1 [FILE2] ... [FILEN]", "Extract all the EXIF and metadata from a photo."

  argument(:files, required: true, banner: "FILE", type: :array)

  def pre_msgs
    say("SCORPION IMAGE EXIF/METADATA", :cyan, :bold)
    say("-----------------------------", :magenta)
  end

  def valid_file?(file)
    unless File.exist?(file)
      say("Invalid file #{file}", :red)
      return false
    end

    unless VALID_EXT.include?(File.extname(file).downcase)
      say("Invalid extension #{file}", :red)
      return false
    end

    return true
  end

  def show_data file, ext
    say("\n--- Datos de #{file} ---", :blue, :bold)
    say("Type:    #{ext.upcase}", :clear)
    say("Size:    #{File.size(file)}")
  end

  def show_exif(file, photo)
    say("\n--- Datos de #{file} ---", :cyan, :bold)
    say("Size:      #{File.size(file)} bytes")

    begin
      say("Modelo:    #{photo.model}", :clear) if photo.model
    rescue; end

    begin
      say("Fecha:     #{photo.date_time}") if photo.date_time
    rescue; end

    begin
      say("ISO:       #{photo.iso}") if photo.iso
    rescue; end

    begin
      say("Software:  #{photo.software}") if photo.software
    rescue; end

    if photo.gps
      begin
        say("Latitud:   #{photo.gps.latitude}")
        say("Longitud:  #{photo.gps.longitude}")
      rescue; end
    end
  end

  def perform(args)
    pre_msgs

    args.each do |file|
      next unless valid_file?(file)

      ext = File.extname(file).downcase

      if [".jpg", ".jpeg"].include?(ext)
        photo = EXIFR::JPEG.new(file)

        if photo.nil? || !photo.exif?
          say("INFO: #{file} doesn't have metadata EXIF.", :magenta)
          return
        end

        show_exif(file, photo)
      elsif
        show_data(file, ext)
      end
    end
  end
end
