require 'rubygems'
require 'mechanize'

class Mechanize::HTTP::Agent
  def response_redirect response, method, page, redirects, referer = current_page
    case @redirect_ok
    when true, :all
      # shortcut
    when false, nil
      return page
    when :permanent
      return page unless Net::HTTPMovedPermanently === response
    end

    log.info("follow redirect to: #{response['Location']}") if log

    raise Mechanize::RedirectLimitReachedError.new(page, redirects) if
      redirects + 1 > @redirection_limit

    redirect_method = method == :head ? :head : :get

    from_uri = page.uri
    @history.push(page, from_uri)
    parser = URI::Parser.new(:UNRESERVED=>URI::PATTERN::UNRESERVED+'\[\]')
    new_uri = from_uri + parser.parse(URI.encode(response['Location'].to_s))
    
    fetch new_uri, redirect_method, {}, [], referer, redirects + 1
  end
end  
