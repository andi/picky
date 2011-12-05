module Picky

  # External libraries.
  #
  require 'active_support/core_ext'
  require 'text'
  require 'yajl' # THINK Maybe replace by multi_json?
  require 'rack' # TODO Remove.
  require 'rack_fast_escape' # TODO Remove.

  # Require the constants.
  #
  require ::File.expand_path '../picky/constants', __FILE__

  # Loader which handles framework and app loading.
  #
  require ::File.expand_path '../picky/loader', __FILE__

  # Load the framework
  #
  # TODO Perhaps move the "Loaded" message?
  #
  Loader.load_framework
  puts "Loaded picky with environment '#{PICKY_ENVIRONMENT}' in #{PICKY_ROOT} on Ruby #{RUBY_VERSION}."

  # Check if delegators need to be installed.
  #
  require ::File.expand_path '../picky/sinatra', __FILE__

  # This is only used in the classic project style.
  #
  class << self
    attr_accessor :logger
  end

end