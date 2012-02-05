#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
=begin
agent = Mechanize.new
agent.download("","")
=end

require 'uri'
require 'net/http'

require "rubygems"
require 'httpclient'
require 'progressbar'
require 'mechanize'

class Mechanize
  def download(url,file)
    url = URI.parse(url)
    cli = HTTPClient.new
    cookie_jar.cookies(url).each do |cookie|
      cli.cookie_manager.parse(cookie.to_s,url)
    end
    
    length = 0;total = 0
    while true
      res = cli.head(url)
      break unless res.status == 302 # HTTP::HTTPFound
      url = URI.parse(URI.encode(res.header["Location"][0].to_s))
    end

    content_length = cli.head(url).header["Content-Length"]
    total = content_length[0].to_s.to_i
    t = Thread.new {
      conn = cli.get_async(url)
      io = conn.pop.content

      f = file
      f = ::File::open(file, "wb") unless file.is_a?(IO) or file.is_a?(Tempfile)
      while str = io.read(40)
        f.write str
        length += str.length
      end
      f.close unless (file.is_a?(IO) or file.is_a?(Tempfile))
    }

    pbar = ProgressBar.new("Loading",total)
    while  total > length
      sleep 1
      pbar.set(length)
    end
    pbar.finish
    t.join
  end
end
