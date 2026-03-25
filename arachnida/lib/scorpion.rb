# frozen_string_literal: true

require_relative "command"

class Scorpion < Command
  desc "./scorpion FILE1 [FILE2 ...]", "Parse image files for EXIF and other metadata."

  argument(:file1, required: true, banner: "FILE1")

  def perform(args)
    say("Scorpion Metadata Scanner", :magenta, :bold)
    say("-----------------------", :magenta)
    args.each do |file|
      say("Processing: #{file}", :white)
    end
    say("-----------------------", :magenta)
    say("Scan complete!", :green, :bold)
  end
end
