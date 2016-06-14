# ==============================
#   .pryrc
# ==============================

# Record how long you hack with Ruby this session.
pryrc_start_time = Time.now

require '~/.pryrc_helpers.rb'

# ___ is to Avoid name conflict
___ = PryrcHelpers

# what are the gems you use daily in REPL? Put them in ___daily_gems
___daily_gems  = %w[benchmark yaml json sqlite3 pg]

# ___pry_gems is for loading vendor plugins for Pry.
___pry_gems = %w[awesome_print hirb pry-byebug pry-stack_explorer]

___daily_gems.___require_gems
___pry_gems.___require_gems

## Enable Pry's show-method in Ruby 1.8.7
# https://github.com/pry/pry/wiki/FAQ#how-can-i-use-show-method-with-ruby-187
if RUBY_VERSION == "1.8.7"
  safe_require('ruby18_source_location', "Install this gem to enable Pry's show-method")
  warn('Ruby 1.8.7 is retired now, please consider upgrade to newer version of Ruby.')
end

# ==============================
#  Some FAQ
# ==============================

# https://github.com/pry/pry/wiki/FAQ#why-doesnt-pry-work-with-ruby-191
if RUBY_VERSION == "1.9.1"
  warn('1.9.1 has known issue with Pry. Please upgrade to 1.9.3-p448 or Ruby 2.0+.')
end

## Why is my emacs shell output showing odd characters?
# [1A[0Ginput> [1B[0Ginput>
# https://github.com/pry/pry/wiki/FAQ#how-can-i-use-show-method-with-ruby-187
# This will fix it.
# Pry.config.auto_indent = false

# ==============================
#  Vulnerability Reminder
# ==============================

if RUBY_REVISION < 43780
  print(
    ___.colorize(
      "YOUR RUBY #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} HAS VULNERABILITIES, PLEASE CONSIDER UPGRADE TO LATEST VERSION. ",
      31
    )
  )
  print(___.colorize("MORE INFORMATION: http://goo.gl/mmcAQz\n", 31))
end

# ==============================
#  Vendor Stuff
# ==============================

###   Printing!
# (1) Awesome Print
# (2) Coderay
# (3) hirb

# ==============================
#   Awesome Print
# ==============================
# Pretty print your Ruby objects with style -- in full color and with proper indentation
# http://github.com/michaeldv/awesome_print
if defined? AwesomePrint
  # The following line enables awesome_print for all pry output,
  # and it also enables paging
  Pry.config.print = proc do |output, value|
    Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output)
  end

  # If you want awesome_print without automatic pagination, use the line below
  # Pry.config.print = proc { |output, value| output.puts value.ai }

  # if defined? Bundler
  #   Gem.post_reset_hooks.reject! { |hook| hook.source_location.first =~ %r{/bundler/} }
  #   Gem::Specification.reset
  #   load 'rubygems/custom_require.rb'
  # end

  # awesome_print config for Minitest.
  if defined? Minitest
    module Minitest::Assertions
      def mu_pp(obj)
        obj.awesome_inspect
      end
    end
  end
end

# ==============================
#   CodeRay
# ==============================
if defined? CodeRay
  CodeRay.scan("example", :ruby).term # just to load necessary files
  # Token colors pulled from: https://github.com/rubychan/coderay/blob/master/lib/coderay/encoders/terminal.rb

  $LOAD_PATH << File.dirname(File.realpath(__FILE__))

  # In CodeRay >= 1.1.0 token colors are defined as pre-escaped ANSI codes
  if Gem::Version.new(CodeRay::VERSION) >= Gem::Version.new('1.1.0')
    require "escaped_colors"
  else
    require "unescaped_colors"
  end

  module CodeRay
    module Encoders
      class Terminal < Encoder
        # override old colors
        TERM_TOKEN_COLORS.each_pair do |key, value|
          TOKEN_COLORS[key] = value
        end
      end
    end
  end
end

# ============================
#   hirb
# ============================
# A mini view framework for console/irb that's easy to use, even while under its influence. Console goodies include a no-wrap table, auto-pager, tree and menu.
# Visit http://tagaholic.me/hirb/ to know more.
begin
  require 'hirb'
  Hirb.enable
  old_print = Pry.config.print
  Pry.config.print = proc do |*args|
    Hirb::View.view_or_page_output(args[1]) || old_print.call(*args)
  end
rescue LoadError
end

# ==============================
#   Pry Configurations
# ==============================

# Editors
#   available options: vim, mvim, mate, emacsclient...etc.
Pry.config.editor = "vim"

# ==============================
#   Pry Prompt
# ==============================
# with AWS:
#             AWS@2.0.0 (main)>
# with Rails:
#             3.2.13@2.0.0 (main)>
# Plain Ruby:
#             2.0.0 (main)>
Pry.config.prompt = proc do |obj, level, _|
  prompt = ""
  prompt << "AWS@" if defined?(AWS)
  prompt << "#{Rails.version}@" if defined?(Rails)
  prompt << "#{RUBY_VERSION}"
  "#{prompt} (#{obj})> "
end

# Exception
Pry.config.exception_handler = proc do |output, exception, _|
  puts(___.colorize "#{exception.class}: #{exception.message}", 31)
  puts(___.colorize "from #{exception.backtrace.first}", 31)
end

# ==============================
#   Custom Commands
# ==============================
Pry::Commands.create_command("format_html") do
  description("Format the html output for [ARGS]")
  command_options(requires_gem: ['nokogiri'])

  def process
    @object_to_interrogate = args.empty? ? target_self : target.eval(args.join(" "))
    cleaned_html = Nokogiri::XML(@object_to_interrogate,&:noblanks)

    colorized_text = Pry.config.color ? CodeRay.scan(cleaned_html, :html).term : cleaned_html
    output.puts colorized_text
  end
end

# ==============================
# Aliases
# ==============================

# Ever get lost in pryland? try w!
Pry.config.commands.alias_command('.w', 'whereami')

# Clear Screen
Pry.config.commands.alias_command('.clr', '.clear')

# Byebug
if defined? PryByebug
  Pry.config.commands.alias_command('.c', 'continue')
  Pry.config.commands.alias_command('.s', 'step')
  Pry.config.commands.alias_command('.n', 'next')
  Pry.config.commands.alias_command('.f', 'finish')
end

# ==============================
#   Welcome to Pry
# ==============================
Pry.active_sessions = 0

Pry.config.hooks.add_hook(:before_session, :welcome) do
    if Pry.active_sessions.zero?
      puts("Hello #{___.user}! I'm Pry #{Pry::VERSION}.")
      puts("I'm Loading Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} and everything else for you:")

      ### Fake Loading Progress bar
      # |====================>
      [*1..9].each do |e|
        print(___.pryrc_progress_bar(e))
        $stdout.flush
        sleep(___.pryrc_speed)
      end

      # Print |==================> Load Completed!
      # 9 is to keep progress bar have the same length (see above each loop)
      print(___.pryrc_progress_bar 9, true)

      puts(___.welcome_messages)
    end
  Pry.active_sessions += 1
end

# ==============================
#   So long, farewell...
# ==============================
Pry.config.hooks.add_hook(:after_session, :farewell) do
  Pry.active_sessions -= 1
  if Pry.active_sessions.zero?
    if ___.true_true_or_false
      puts(___.farewell_messages)
    else
      interpreted_time = ___.interpret_time(Time.now - pryrc_start_time)
      interpreted_time = 'ever' if interpreted_time == '0 second'
      puts "Hack with Ruby for #{interpreted_time}!"
    end
  end
end
