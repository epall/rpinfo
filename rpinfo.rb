require 'rubygems'
require 'net/http'
require 'open-uri'
require 'uri'
require 'nokogiri'

#1: Simple POST
res = Net::HTTP.post_form(URI.parse('http://prod3.server.rpi.edu/peopledirectory/search.do'),
                          {'query'=>'Eric Allen', 'datasetName' => 'directory', 'qct' => '10'})
doc = Nokogiri::HTML(open(res['location']))
people = doc.css('td.listingName a')
top_hit = people[0]

person_page = Nokogiri::HTML(open('http://prod3.server.rpi.edu/peopledirectory/'+top_hit.attribute('href')))
email_glyphs = person_page.css('td.email img')
email_glyphs.each do |glyph|
  puts glyph['src'].split('/')[10].split('.')[0].to_i
end
