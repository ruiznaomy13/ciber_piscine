# frozen_string_literal: true

require "optparse"

class Command
  COLORS = {
    clear: 0,
    bold: 1,
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37
  }.freeze

  class Error < StandardError
  end

  class RequiredArgumentMissingError < Error
  end

  class Argument
    attr_reader :name, :type, :default, :required, :banner

    def initialize(name, options = {})
      @name = name.to_s
      @type = options[:type] || :string
      @default = options[:default]
      @required = options.fetch(:required, true)
      @banner = options[:banner] || name.to_s.upcase
    end
  end

  class Option < Argument
    attr_reader :aliases, :desc

    def initialize(name, options = {})
      super
      @required = options.fetch(:required, false)
      @aliases = Array(options[:aliases])
      @desc = options[:desc] || ""
    end

    def switch_name()
      @name.to_s.tr("_", "-")
    end
  end

  class << self
    def arguments()
      @arguments ||= []
    end

    def options()
      @options ||= {}
    end

    def argument(name, options = {})
      arguments << Argument.new(name, options)
    end

    def option(name, options = {})
      self.options[name.to_sym] = Option.new(name, options)
    end

    def desc(usage, description)
      @usage = usage
      @description = description
    end

    def start(args = ARGV)
      new.parse(args)
    rescue OptionParser::ParseError => e
      instance = new
      instance.say("ERROR: #{e.message}", :red, :bold)
      instance.show_usage
      exit(1)
    rescue Error => e
      instance = new
      instance.say("ERROR: #{e.message}", :red, :bold)
      instance.show_usage
      exit(1)
    end

    def usage()
      @usage
    end

    def description()
      @description
    end
  end

  attr_reader :options

  def initialize()
    @options = Hash.new { |h, k| h[k.to_s] if k.is_a?(Symbol) }
  end

  def say(message, *styles)
    puts(set_color(message, *styles))
  end

  def set_color(string, *styles)
    return string if styles.empty? || !STDOUT.tty?
    codes = styles.map { |s| COLORS[s.to_sym] }.compact
    return string if codes.empty?
    "\e[#{codes.join(";")}m#{string}\e[0m"
  end

  def show_usage()
    puts("\nUsage: #{self.class.usage}")
    puts(self.class.description) if self.class.description
  end

  def parse(args)
    @args = args.dup
    setup_defaults
    build_parser.parse!(@args)
    check_required_options
    process_arguments
    perform(@positional_args)
  end

  private

    def setup_defaults()
      self.class.options.each do |name, opt|
        @options[name.to_s] = opt.default if opt.default
        @options[name.to_s] = false if opt.type == :boolean && opt.default.nil?
      end
    end

    def build_parser()
      OptionParser.new do |parser|
        self.class.options.each do |name, opt|
          switches = build_switches(opt)
          parser.on(*switches, opt.desc) { |v| @options[name.to_s] = v }
        end
      end
    end

    def build_switches(opt)
      switches = []
      long = "--#{opt.switch_name}"
      if opt.type == :boolean
        switches << long
      elsif opt.type == :numeric
        switches << "#{long} N" << Numeric
      else
        switches << "#{long} VALUE"
      end
      opt.aliases.each { |a| switches << a }
      switches
    end

    def check_required_options()
      self.class.options.each do |name, opt|
        if opt.required && !@options.key?(name.to_s)
          raise(RequiredArgumentMissingError, "Missing required option: --#{opt.switch_name}")
        end
      end
    end

    def process_arguments()
      @positional_args = []
      self.class.arguments.each do |spec|
        val = @args.shift
        if val.nil?
          raise(RequiredArgumentMissingError, "Missing required argument: #{spec.banner}") if spec.required
          @positional_args << spec.default
        else
          @positional_args << val
        end
      end
      @positional_args.concat(@args)
    end

    def perform(args)
      raise("Subclasses must implement perform(args)")
    end
end
