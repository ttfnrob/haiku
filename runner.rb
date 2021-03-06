require 'xmlsimple'
require 'net/http'
require 'active_support/all'

# See https://github.com/jnxpn/haiku_generator

def haiku_search(incoming, arpabetfile)
  dictionary = File.open(arpabetfile, 'r')
  book_to_string = words_in_book = book_words = syls = nil

  book_to_string = incoming
  words_in_book = book_to_string.gsub(/[^A-Za-z\s]/, '').split(' ')
  book_words = words_in_book.each {|word| word.upcase!}
  syls = {}

  dictionary.each_line do |line|
    word, phonemes = line.split('  ')
    syllables = phonemes.split(' ')
    total_syls = 0
    syllables.each do |syl|
      if syl =~ /\d/
        total_syls += 1
      end
    end
    syls[word] = total_syls
  end


  book_words.each_index do |i|
    j = i
    syls_per_line = [5,7,5]
    haiku = []
    success = true
    bad_ending_words = ['THE', 'AND', 'OR', 'A', 'OF', 'TO', 'BUT', 'TO']

    syls_per_line.each do |syl|
      remaining_syl = syl
      while (remaining_syl > 0)  &&  (syls[book_words[j]] != nil) && (syls[book_words[j]] <= remaining_syl) && (syls[book_words[j]] > 0)
        haiku << book_words[j]
        remaining_syl -= syls[book_words[j]]
        j += 1
      end
      if remaining_syl != 0
        success = false
        break
      end
      haiku << "\n"
    end

    if success == true && !(bad_ending_words.include?(haiku[-2]))
      titlecase = [] 
      haiku.each do |h|
        if h == "\n"
          titlecase << h
        else
          titlecase << h.titlecase
        end
      end
      return titlecase.join(' ')
    end
  end
end

url = 'http://feeds.bbci.co.uk/news/rss.xml?edition=int'
xml_data = Net::HTTP.get_response(URI.parse(url)).body

data = XmlSimple.xml_in(xml_data)["channel"].first

data['item'].each_with_index do |paper, index|
  abstract = paper['description'].first
  url = paper['link'].first
    
  haikus = haiku_search(abstract, 'cmudict.txt')
  
  puts "----------------"
  puts url
  puts haikus
end