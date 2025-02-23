require 'parslet'

module RubyHandlebars
  class Parser < Parslet::Parser
    rule(:space)       { match('\s').repeat(1) }
    rule(:space?)      { space.maybe }
    rule(:dot)         { str('.') }
    rule(:gt)          { str('>')}
    rule(:hash)        { str('#')}
    rule(:slash)       { str('/')}
    rule(:ocurly)      { str('{')}
    rule(:ccurly)      { str('}')}
    rule(:pipe)        { str('|')}
    rule(:eq)          { str('=')}
    rule(:tilde)       { str('~')}
    rule(:osquare)     { str('[')}
    rule(:csquare)     { str(']')}


    rule(:docurly)     { ocurly >> ocurly >> tilde.maybe }
    rule(:dccurly)     { tilde.maybe >> ccurly >> ccurly }
    rule(:tocurly)     { ocurly >> ocurly >> ocurly >> tilde.maybe }
    rule(:tccurly)     { tilde.maybe >> ccurly >> ccurly >> ccurly }

    rule(:else_kw)     { str('else') }
    rule(:as_kw)       { str('as') }

    rule(:identifier)  { (else_kw >> (space >> identifier >> (space >> parameters).maybe).maybe >> space? >> dccurly).absent? >> match['@\-a-zA-Z0-9_\?'].repeat(1) }
    rule(:key_ident)   { (else_kw >> (space >> identifier >> (space >> parameters).maybe).maybe >> space? >> dccurly).absent? >> osquare >> match['@\-a-zA-Z0-9_\?'].repeat(1) >> csquare }
    rule(:directory)   { (else_kw >> (space >> identifier >> (space >> parameters).maybe).maybe >> space? >> dccurly).absent? >> match['@\-a-zA-Z0-9_\/\?'].repeat(1) }
    rule(:path)        { identifier >> (dot >> (identifier | else_kw | key_ident)).repeat }

    rule(:nocurly)     { match('[^{}]') }
    rule(:eof)         { any.absent? }
    rule(:template_content) {
      (
        nocurly.repeat(1) | # A sequence of non-curlies
        ocurly >> nocurly | # Opening curly that doesn't start a {{}}
        ccurly            | # Closing curly that is not inside a {{}}
        ocurly >> eof       # Opening curly that doesn't start a {{}} because it's the end
      ).repeat(1).as(:template_content) }

    rule(:unsafe_replacement) { docurly >> space? >> path.as(:replaced_unsafe_item) >> space? >> dccurly }
    rule(:safe_replacement) { tocurly >> space? >> path.as(:replaced_safe_item) >> space? >> tccurly }

    rule(:number)      { (match('\d').repeat(1) >> str('.').maybe >> match('\d').repeat).as(:num_content) }

    rule(:sq_string)   { match("'") >> match("[^']").repeat.maybe.as(:str_content) >> match("'") }
    rule(:dq_string)   { match('"') >> match('[^"]').repeat.maybe.as(:str_content) >> match('"') }
    rule(:string)      { sq_string | dq_string }

    rule(:parameter)   {
      (as_kw >> space? >> pipe).absent? >>
      (
        (number | path | string).as(:parameter_name) |
        (str('(') >> space? >> identifier.as(:safe_helper_name) >> (space? >> parameters.as(:parameters)).maybe >> space? >> str(')'))
      )
    }
    rule(:parameters)  { parameter >> (space >> parameter).repeat }

    rule(:argument)    { identifier.as(:key) >> space? >> eq >> space? >> parameter.as(:value) }
    rule(:arguments)   { argument >> (space >> argument).repeat }

    rule(:unsafe_helper) { docurly >> space? >> identifier.as(:unsafe_helper_name) >> (space? >> parameters.as(:parameters)).maybe >> space? >> dccurly }
    rule(:safe_helper) { tocurly >> space? >> identifier.as(:safe_helper_name) >> (space? >> parameters.as(:parameters)).maybe >> space? >> tccurly }

    rule(:helper) { unsafe_helper | safe_helper }

    rule(:as_block_helper) {
      docurly >>
      hash >>
      identifier.capture(:helper_name).as(:helper_name) >>
      space >> parameters.as(:parameters) >>
      space >> as_kw >> space >> pipe >> space? >> parameters.as(:as_parameters) >> space? >> pipe >>
      space? >>
      dccurly >>
      scope {
        block
      } >>
      scope {
        docurly >> space? >> else_kw >> space? >> dccurly >> scope { block_item.repeat.as(:else_block_items) }
      }.maybe >>
      dynamic { |src, scope|
        docurly >> slash >> str(scope.captures[:helper_name]) >> dccurly
      }
    }

    rule(:block_helper) {
      docurly >>
      hash >>
      identifier.capture(:helper_name).as(:helper_name) >>
      (space >> parameters.as(:parameters)).maybe >>
      space? >>
      dccurly >>
      scope {
        block
      } >>
      scope {
        docurly >> space? >> else_kw >> space >> dynamic { |_src, scope| str(scope.captures[:helper_name]) }.as(:helper_name) >> (space >> parameters.as(:parameters)).maybe >> space? >> dccurly >> scope { block_item.repeat.as(:else_block_items) }
      }.repeat.as(:elsif_block_items) >>
      scope {
        docurly >> space? >> else_kw >> space? >> dccurly >> scope { block_item.repeat.as(:else_block_items) }
      }.maybe >>
      dynamic { |src, scope|
        docurly >> slash >> str(scope.captures[:helper_name]) >> dccurly
      }
    }

    rule(:partial) {
      docurly >>
      gt >>
      space? >>
      directory.as(:partial_name) >>
      space? >>
      arguments.as(:arguments).maybe >>
      space? >>
      dccurly
    }

    rule(:block_item) { (template_content | unsafe_replacement | safe_replacement | helper | partial | block_helper | as_block_helper) }
    rule(:block) { block_item.repeat.as(:block_items) }

    root :block
  end
end
