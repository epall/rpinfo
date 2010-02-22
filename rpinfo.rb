require 'rubygems'
require 'net/http'
require 'open-uri'
require 'uri'
require 'nokogiri'

class RPIPerson
  attr_reader :name, :email, :class, :curriculum

  def initialize(name)
    @name = name
    first_name = name.split(' ')[0]
    last_name = name.split(' ')[1]
    top_hit = filter_for_name(name)

    if top_hit.nil?
      # try just last name
      people = search_by_name(last_name)
      top_hit = people.first if people.count == 1
    end
    
    # try formal first names
    top_hit ||= filter_for_name("Thomas "+last_name) if first_name == "Tom"
    top_hit ||= filter_for_name("Pete "+last_name) if first_name == "Peter"
    top_hit ||= filter_for_name("Joseph "+last_name) if first_name == "Joe"
    
    raise "Person not found: #{name}" unless top_hit
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
      when 38
        @email << '.'
      when 39
        @email << '@'
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
  
  private
  
  def search_by_name(name)
    res = Net::HTTP.post_form(URI.parse('http://prod3.server.rpi.edu/peopledirectory/search.do'),
                        {'query'=>name, 'datasetName' => 'directory', 'qct' => '10'})
    doc = Nokogiri::HTML(open(res['location']))
    doc.css('td.listingName a')
  end
  
  def filter_for_name(name)
    possibilities = search_by_name(name).find_all do |person|
      first_name = name.split(' ')[0]
      last_name = name.split(' ')[1]
      person.content.match(/^#{last_name},\s*#{first_name}/)
    end
    raise "Multiple people under name #{name}" if possibilities.count > 1
    return possibilities.first
  end
end
