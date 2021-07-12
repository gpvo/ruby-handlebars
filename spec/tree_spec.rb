require_relative 'spec_helper'
require_relative '../lib/ruby-handlebars/parser'
require_relative '../lib/ruby-handlebars/tree'


describe RubyHandlebars::Transform do
  let(:parser) {RubyHandlebars::Parser.new}
  let(:transform) {RubyHandlebars::Transform.new}

  def get_ast(content)
    transform.apply(parser.parse(content))
  end

end