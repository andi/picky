# Run with:
#   bundle exec unicorn -c unicorn.cfg
#
# Example queries:
#   curl 'localhost:8080/texts?query=hi'
#   curl 'localhost:8080/texts?query=m'
#   curl 'localhost:8080/texts?query=ho~'
#
# With the command line interface:
#   picky search localhost:8080/texts
#

require 'sinatra/base'
require File.expand_path '../../../lib/picky', __FILE__
require File.expand_path '../model', __FILE__

class UnicornApp < Sinatra::Application

  disable :logging

  extend Picky::Sinatra

  indexing splits_text_on: /[\s\t]/

  texts = Picky::Index.new :texts do
    source   Model.all
    category :text,
             partial: Picky::Partial::Substring.new(from: 1),
             similarity: Picky::Similarity::DoubleMetaphone.new(3)
  end

  # Index and load on startup.
  #
  texts.index
  texts.load

  # Index and load on USR1 signal.
  #
  Signal.trap('USR1') do
    texts.reindex # kill -USR1 <pid>
  end

  text_search = Picky::Search.new texts
  get '/texts' do
    results = text_search.search params[:query], params[:ids] || 20, params[:offset] || 0
    results.to_json
  end

end