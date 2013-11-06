# -*- coding: utf-8 -*-
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'mechanize'
require 'writeexcel'

BASE_URL = 'http://avito.ru'
ALT_URL = 'http://m.avito.ru' 
PAGES = { realty:'http://m.avito.ru/catalog/rostov-na-donu/nedvizhimost',
  things:'http://m.avito.ru/catalog/rostov-na-donu/lichnye_veschi',
  transport:'http://m.avito.ru/catalog/rostov-na-donu/transport',
  consumer_electronics:'http://m.avito.ru/catalog/rostov-na-donu/bytovaya_elektronika',
  animals:'http://m.avito.ru/catalog/rostov-na-donu/zhivotnye',
  recreation:'http://m.avito.ru/catalog/rostov-na-donu/hobbi_i_otdyh',
  for_house:'http://m.avito.ru/catalog/rostov-na-donu/dlya_doma_i_dachi',
  services:'http://m.avito.ru/catalog/rostov-na-donu/uslugi' }

def harvest_categories(category)
  @cat = category
  puts "Собираю категории..."
  if PAGES.include?(category.to_sym)
    @urls_private = [] 
    @urls_agency = []
    url = PAGES[category.to_sym]
    index_page = Nokogiri::HTML(open(url))
    index_page.css(".arrow+ .arrow a").each do |t| # harvesting a categories urls
      @urls_private << BASE_URL + t['href'] + '?view=list&user=1'
      @urls_agency  << BASE_URL + t['href'] + '?view=list&user=2'
    end
  else
    raise "Category #{category} not found"
  end
end

def harvest_all_pages_from_category(kind) # @urls_private or @urls_agency, twice 
  if kind == @urls_agency
    @agency_or_private = "Компания"
    puts 'agency'
  elsif kind == @urls_private
    @agency_or_private = "Частное"
    puts 'private'
  else
    raise "Kind #{kind} not found :("
  end

  puts "Собираю ссылки со страниц категорий"
  @all_pages_in_cat = []
  kind.each do |url|
    category_page = Nokogiri::HTML(open(url))
    @all_pages_in_cat << category_page # adding first page manually

    while category_page.at_css(".next")            # if next button exists - giving a new victim for Nokogiri
      category_page = BASE_URL + category_page.at_css(".next")['href']
      category_page = Nokogiri::HTML(open(category_page))
      @all_pages_in_cat << category_page
      puts "Собираю ссылки со страницы: #{@all_pages_in_cat.count}, пауза 1-2 секунды"
      sleep(rand(1..2))
    end
    
  end
  
  @all_fckn_links = [] 
  @all_pages_in_cat.each do |obj| # get all links from all pages in the particular category
    obj.css(".fader .second-link").each do |link|
      @all_fckn_links << ALT_URL + link['href']
    end
  end
  
end

def write_excel_file(filename)
  # Create a new Excel Workbook
  workbook = WriteExcel.new(filename+".xls")
  
  # Add worksheet(s)
  worksheet  = workbook.add_worksheet
  #@container.uniq! # remove doubles
  1.upto(@container.count) do |i|
    worksheet.write("A#{i}", @container[i-1][0])
    worksheet.write("B#{i}", @container[i-1][1])
    worksheet.write("C#{i}", @container[i-1][2])
    worksheet.write("D#{i}", @container[i-1][3])
  end

  # write to file
  workbook.close
  @container.clear
  #@all_fckn_links.clear
  #@all_pages_in_cat.clear
end

def get_data#(time)
  a = Mechanize.new { |agent|  # Valera! It's your time now
    agent.user_agent_alias = 'Mac Safari'
  }
  puts "Сбор данных... Это может занять до нескольких часов, Ctrl-C - прервать работу"
  # имя, телефон, частное?, категория
 
    
  @container = []
  @all_fckn_links.each_with_index do |url, counter| 
    # whew... good luck!
    arr = []
    
    begin  # simple antiban waiter
      page = a.get(url)
      puts '***'
      sleep(rand (1..2))
      page1 = page.link_with(dom_id:'showPhoneBtn').click
    rescue Mechanize::ResponseCodeError => exception
      if exception.response_code == '403'
        puts "Похоже, нас забанили. Жду 15 минут и повторяю (скоро разбанят)"
        puts exception
        sleep(900)
        retry
      else
        puts "Похоже, страница с объявлением была удалена"
        puts exception
      end
    end
    phone = page1.link_with(href:/tel/).text
    # change me if i dont work
    name = page1.at("li:nth-child(2)").text.delete("\n").strip.match(/\ .*/).to_s.strip
    cat = page1.at("li:nth-child(6)").text
    if cat =~ /Ростов/
      cat = page1.at("li:nth-child(7)").text.delete("\n").strip.match(/\ .*/).to_s.strip
    elsif cat !~ /Категория/
      cat = page1.at("li:nth-child(5)").text.delete("\n").strip.match(/\ .*/).to_s.strip # TODO: make a helper
    else
      cat = cat.delete("\n").strip.match(/\ .*/).to_s.strip
    end
    arr << name << phone << cat << @agency_or_private
    @container << arr
    q = @container.count
    c =  counter+1
    # write each 5000 positions to excel?
    puts q
    if q >= 1000 # ugly
      puts "Пишу excel файл"
      write_excel_file(@cat.to_s+"_"+ @agency_or_private + c.to_s + "|" + @all_fckn_links.count.to_s)
    #else
    #  next
    end
  
  end
  write_excel_file(@cat.to_s+"_"+ @agency_or_private + c.to_s + "|" + @all_fckn_links.count.to_s)
  @all_fckn_links.clear
  @all_pages_in_cat.clear

end

def clearing
 
end
  # page = a.get('http://m.avito.ru/catalog/rostov-na-donu')
  # # недвижимость, личные вещи, транспорт, бытовая электроника, услуги, для дома и дачи, хобби и отдых, животные
  # page.links_with(:dom_class => "icon-link second-link").each_with_index do |link, t|
  #   puts 'Loading %-30s %s' % [link.href, link.text]
  #   p t+1
  #   product_page = link.click 
  
  # end


  # # Mechanize::Page::Link.new(node, a, page).click
  # page = page.link_with(dom_class:"next").click  
  # # next_page = true ? next_page.href : 'end - of - the - line'
  # page.links_with(:dom_class => "icon-link second-link").each_with_index do |link, t|
  #   puts 'Loading %-30s %s' % [link.href, link.text]
  #   p t+1
  # end

  # #page = next_page.click



