#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
load './avitoparser.rb'
if ARGV[0] == nil # || ARGV[0] != PAGES.select 
  puts "Использование: > ruby ruby_me.rb категория \n
  где категория может быть: \n
  realty \n
  things \n
  transport \n
  consumer_electronics \n
  animals \n
  recreation \n
  for_house \n
  services \n"
  exit
else
  harvest_categories(ARGV[0])
  harvest_all_pages_from_category(@urls_agency)
  get_data
  #clearing
  harvest_all_pages_from_category(@urls_agency)
  get_data
  #clearing
end
#@all_fckn_links.count
# => 2598 
