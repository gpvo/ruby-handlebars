module RubyHandlebars
  module Escapers
    class DummyEscaper
      def self.escape(value)
        value
      end
    end
  end
end