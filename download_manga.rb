require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'action_view'
require File.expand_path('../mechanize_patch', __FILE__)
require File.expand_path('../mechanize_downloader', __FILE__)
include ActionView::Helpers::NumberHelper
require 'yaml'

seriesID = (defined? SERIES_ID) ? SERIES_ID : ARGV[0]
raise "series id missing " unless seriesID
USER_INFO = YAML.load_file(File.expand_path('../user_info.yml', __FILE__))
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil

AGENT = Mechanize.new
AGENT.pluggable_parser['application/zip'] = Mechanize::Download

def login
  page1 = AGENT.get "http://www.mangatraders.com"
  page1.forms[1]["login-user"] = USER_INFO[:user]
  page1.forms[1]["login-pass"] = USER_INFO[:pass]
  page1.forms[1].submit
end  

file_doc = Nokogiri::XML(AGENT.get("http://www.mangatraders.com/manga/series/#{seriesID}/files").body)

files = file_doc.xpath('//file').map{|f| {
  id: f.xpath('@id').text,
  size: f.xpath('file_size').text,
  userid: f.xpath('userid').text
  }}
files.each do |file|
  login
  AGENT.request_headers['Referer']="http://www.mangatraders.com/view/file/#{file[:id]}"
  AGENT.user_agent = Mechanize::AGENT_ALIASES['Mac Mozilla']  
  url = "http://www.mangatraders.com/download/file/#{file[:id]}"
  header = AGENT.head(url)
  filename = header.extract_filename.sub("#{file[:userid]}-",'')
  next if File.exist? filename
  puts "yaaargh getting #{filename}"
  sleep 10
  AGENT.download(url, filename)
  fsize = number_to_human_size(File.size(filename), :strip_insignificant_zeros => false, :significant => false, :precision => 2).sub(' ', '')
  puts "expected #{file[:size]} but got #{fsize}" unless fsize.strip == file[:size].strip
end
