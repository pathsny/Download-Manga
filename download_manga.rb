require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'action_view'
require File.expand_path('../mechanize_patch', __FILE__)
require File.expand_path('../mechanize_downloader', __FILE__)
include ActionView::Helpers::NumberHelper
require 'yaml'

raise "series id missing " unless ARGV[0]
USER_INFO = YAML.load_file(File.expand_path('../user_info.yml', __FILE__))

AGENT = Mechanize.new
AGENT.pluggable_parser['application/zip'] = Mechanize::Download

def login
  page1 = AGENT.get "http://www.mangatraders.com"
  page1.forms[1]["login-user"] = USER_INFO[:user]
  page1.forms[1]["login-pass"] = USER_INFO[:pass]
  page1.forms[1].submit.body
end  

file_doc = Nokogiri::XML(AGENT.get("http://www.mangatraders.com/manga/series/#{ARGV[0]}/files").body)
files = file_doc.xpath('//file').map{|f| [f.xpath('@id').text, f.xpath('file_disp').text, f.xpath('file_size').text]}
files.each do |file|
  login
  AGENT.request_headers['Referer']="Referer:http://www.mangatraders.com/view/file/#{file[0]}"
  url = "http://www.mangatraders.com/download/file/#{file[0]}"
  header = AGENT.head(url)
  filename = "#{file[1]}#{File.extname(header.extract_filename)}"
  next if File.exist? filename
  puts "yaaargh getting #{filename}"
  sleep 10
  AGENT.download(url, filename)
  fsize = number_to_human_size(File.size(filename), :strip_insignificant_zeros => false, :significant => false, :precision => 2).sub(' ', '')
  puts "expected #{file[2]} but got #{fsize}" unless fsize.strip == file[2].strip
end
