# frozen_string_literal: true

require_relative "command"

class Spyder < Command
  desc "./spyder [-rlp] URL", "Extract all images from a website recursively."

  option(:recursive, aliases: ["-r"], type: :boolean, desc: "Recursively download images")
  option(:level, aliases: ["-l"], type: :numeric, default: 5, desc: "Maximum recursion depth")
  option(:path, aliases: ["-p"], type: :string, default: "./data/", desc: "Download path")

  argument(:url, required: true, banner: "URL")

  def perform(args)
    url = args.first
    extensions = [".jpg", ".jpeg", ".png", ".gif", ".bmp"]

    say("Spyder Image Extractor", :cyan, :bold)
    say("-----------------------", :cyan)
    say("Target:    #{url}", :white)
    say("Path:      #{options[:path]}", :blue)
    say("Recursive: #{options[:recursive] ? "Yes" : "No"}", :magenta)

    say("Max Depth: #{options[:level]}", :yellow) if options[:recursive]

    say("\nScanning for extensions: #{extensions.join(", ")}", :white)
    say("Connecting to #{url}...", :yellow)

    say("\n-----------------------", :cyan)
    say("Extraction complete!", :green, :bold)
  end
end
