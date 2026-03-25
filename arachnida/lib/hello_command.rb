# frozen_string_literal: true

require_relative "command"

class HelloCommand < Command
  desc "hello [OPTIONS] NAME", "Greet someone"

  argument :name, required: true

  option :repeat, aliases: ["-r"], type: :boolean, desc: "Repeat greeting"
  option :times, aliases: ["-t"], type: :numeric, desc: "Number of repetitions", requires: :repeat

  def perform(args)
    name = args[0]
    times = @options["repeat"] ? (@options["times"] || 5) : 1

    times.times do |i|
      say("Hello, #{name}! (#{i + 1}/#{times})", :green)
    end
  end
end

HelloCommand.start
