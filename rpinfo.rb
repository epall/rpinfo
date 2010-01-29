require 'rubygems'
require 'net/http'
require 'open-uri'
require 'uri'
require 'nokogiri'

class RPIPerson
  attr_reader :name, :email, :class, :curriculum

  def initialize(name)
    @name = name
    res = Net::HTTP.post_form(URI.parse('http://prod3.server.rpi.edu/peopledirectory/search.do'),
                        {'query'=>name.gsub(' ', ' AND '), 'datasetName' => 'directory', 'qct' => '10'})
    doc = Nokogiri::HTML(open(res['location']))
    people = doc.css('td.listingName a')
    top_hit = people.find do |person|
      first_name = name.split(' ')[0]
      last_name = name.split(' ')[1]
      person.content.match(/^#{last_name},\s*#{first_name}/)
    end
    raise "Person not found" unless top_hit
    person_url = 'http://prod3.server.rpi.edu/peopledirectory/'+top_hit.attribute('href')

    person_page = Nokogiri::HTML(open(person_url))
    email_glyphs = person_page.css('td.email img')
    @email = ''
    email_glyphs.each do |glyph|
      value = glyph['src'].split('/')[10].split('.')[0].to_i
      case value
      when 1..21
        @email << (value + 'a'[0] - 1).chr
	  when 22..27
        @email << (value + 'a'[0]-2).chr
      when 28..36
        @email << (value-28 + '1'[0]).chr
      when 37
        @email << '0'
      when 99
        @email << '@rpi.edu'
      else
        @email << '?'
      end
    end

    person_page.css('tr th').each do |title|
      text = title.content.strip
      if text == 'Class:'
        @class = title.next.next.content.strip
      end
      if text == 'Curriculum:'
        @curriculum = title.next.next.content.strip
      end
    end
  end
end
