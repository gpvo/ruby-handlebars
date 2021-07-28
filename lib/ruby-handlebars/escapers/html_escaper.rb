require 'cgi'

module RubyHandlebars
  module Escapers
    class HTMLEscaper
      def self.escape(value)
        CGI::escapeHTML(value)
      end
    end
  end
end
