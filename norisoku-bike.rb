#!/home/resessh/.rbenv/shims/ruby
# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'rss'
require './rss_cdata'

$items = []
class Item
	attr_accessor :title, :link, :description, :date, :content_encoded
	def initialize(link_address)
		@link = link_address
		document = Nokogiri::HTML(open(link_address).read)
		@title = document.xpath('//head/title').text.split(/\s+:\s+/)[0]
		@description = document.xpath('//head/meta[@property="og:description"]/@content').text
		@date = document.xpath('//time[@pubdate="pubdate"]/@datetime').text
		content = document.xpath('//div[@class="article-body-inner"]')
		content.xpath('//div[@class="blogroll-channel"]').remove
		@content_encoded = content.inner_html
	end
end

def get_page(page_address)
	document = Nokogiri::HTML(open(page_address).read)
	document.xpath("//h1[@class='article-title']/a/@href").each do |link|
		$items.push(Item.new(link))
	end
end

get_page('http://norisoku.com/archives/cat_858196.html')
get_page('http://norisoku.com/archives/cat_858196.html?p=2')

rss = RSS::Maker.make("1.0") do |rss|
	rss.channel.about = 'http://resessh.net/rss.xml'
	rss.channel.title = '乗り物速報 - バイク'
	rss.channel.description = '乗り物速報のバイク関連記事のみを抽出した非公式RSSです'
	rss.channel.link = 'http://norisoku.com/'
	rss.channel.language = 'ja'
	rss.channel.date = Time.now.to_s

	$items.each do |items|
		item = rss.items.new_item
		item.title = items.title
		item.link = items.link
		item.description = items.description
		item.date = items.date
		item.content_encoded = items.content_encoded
	end
end.to_s

output_file = File.open("norisoku-bike.rdf", "w")
output_file.write(rss)
output_file.close