require 'nokogiri'
require 'json'

module MtgList
  class Database
    @@all_hash = nil
    @@sets_hash = {}

    def initialize(dir_path)
      @dir_path = dir_path
      if (@@all_hash.nil?)
        File.open(dir_path + '/AllCards-x.json') do |file|
          @@all_hash = JSON.load(file)
        end
      end
    end

    def card
      @@all_hash
    end

    def set(set_name)
      if (!@@sets_hash.has_key?(set_name))
        File.open(@dir_path + '/' + set_name + '-x.json') do |file|
          @@sets_hash[set_name] = JSON.load(file)
        end
      end
      @@sets_hash[set_name]
    end

    def japanese_card_name(card_name)
      card = @@all_hash[card_name]
      sets = card['printings']
      sets.each do |set_name|
        set_hash = set(set_name)
        next if !set_hash.has_key?('cards')
        set_hash['cards'].each do |set_card|
          next if set_card['name'] != card_name
          next if !set_card.has_key?('foreignNames')
          set_card['foreignNames'].each do |foreign_name|
            if foreign_name['language'] == 'Japanese'
              return foreign_name['name']
            end
          end
        end
      end 
      return nil
    end
  end

  class Pool
    def initialize(plain_list, db)
      @land_pile       = MtgList::CardPile.new('土地')
      @white_pile      = MtgList::CardPile.new('白')
      @blue_pile       = MtgList::CardPile.new('青')
      @black_pile      = MtgList::CardPile.new('黒')
      @red_pile        = MtgList::CardPile.new('赤')
      @green_pile      = MtgList::CardPile.new('緑')
      @multicolor_pile = MtgList::CardPile.new('多色')
      @colorless_pile  = MtgList::CardPile.new('無色')
      pool = plain_list.scan(/^(\d+) (.*)$/)
      pool.each do |cards|
	quantity = cards[0].to_i
        card_name_combined = cards[1]
        card_names = card_name_combined.split("/")
        
        japanese_card_names = []
        types = []
        colors = []
        card_names.each do |card_name|
          card_hash = db.card[card_name]
          japanese_card_names.push(db.japanese_card_name(card_name))
          types.concat(card_hash['types'])
          if card_hash.has_key?('colors')
            colors.concat(card_hash['colors'])
          end
        end
        colors = colors.uniq
        
        card = MtgList::Cards.new(card_names, japanese_card_names, quantity)
        

        if types.include?('Land')
          @land_pile.add(card)
        elsif colors.size < 0
          @colorless_pile.add(card)
        elsif colors.size > 1
          @multicolor_pile.add(card)
        elsif colors.include?('White')
          @white_pile.add(card)
        elsif colors.include?('Blue')
          @blue_pile.add(card)
        elsif colors.include?('Black')
          @black_pile.add(card)
        elsif colors.include?('Red')
          @red_pile.add(card)
        elsif colors.include?('Green')
          @green_pile.add(card)
	end
      end
    end

    def output_html
      result = ''
      result += @white_pile.output_html
      result += @blue_pile.output_html
      result += @black_pile.output_html
      result += @red_pile.output_html
      result += @green_pile.output_html
      result += @multicolor_pile.output_html
      result += @colorless_pile.output_html
      result += @land_pile.output_html
      result
    end
  end

  class Deck
    def initialize(plain_list, db)
      @land_pile       = MtgList::CardPile.new('土地')
      @creature_pile      = MtgList::CardPile.new('クリーチャー')
      @spell_pile       = MtgList::CardPile.new('呪文')
      @sideboard_pile      = MtgList::CardPile.new('サイドボード')
      pool = plain_list.scan(/^(\d*) ?(.*)$/)
      is_side = false
      pool.each do |cards|
        if cards[0].size == 0
          is_side = true
          next
        end
	quantity = cards[0].to_i
        card_name_combined = cards[1]
        card_names = card_name_combined.split("/")
        
        japanese_card_names = []
        types = []
        card_names.each do |card_name|
          card_hash = db.card[card_name]
          japanese_card_names.push(db.japanese_card_name(card_name))
          types.concat(card_hash['types'])
        end
        
        card = MtgList::Cards.new(card_names, japanese_card_names, quantity)
        if is_side
          @sideboard_pile.add(card)
        elsif types.include?('Land')
          @land_pile.add(card)
        elsif types.include?('Creature')
          @creature_pile.add(card)
        else
          @spell_pile.add(card)
	end
      end
    end

    def output_html
      result = ''
      result += @land_pile.output_html
      result += @creature_pile.output_html
      result += @spell_pile.output_html
      result += @sideboard_pile.output_html
      result
    end
  end
  
  class CardPile
    def initialize(name)
      @name = name
      @cards = []
    end
    
    def add(card)
      @cards << card
    end

    def output_html
      return "" if @cards.size == 0
      count = 0;
      @cards.each do |card|
        count += card.quantity
      end
      result = '<div class="mtg__pile">'
      result += '<p class="mtg__pile__header"><span class="mtg__pile__name">' + @name + '</span><span class="mtg__pile__count"> (' + count.to_s + ')</span></p>'
      result += '<ul class="mtg__pile__body">'
      @cards.sort_by! { |card| card.name }
      @cards.each do |card|
        result += card.output_html
      end
      result += "</ul></div>"
    end
  end

  class Cards
    def initialize(names, japanese_names, quantity)
      @name = names.join('+')
      @japanese_name = japanese_names.join('+')
      @quantity = quantity
    end 
    
    def quantity
      @quantity
    end

    def full_name
      if @japanese_name.nil? || @japanese_name.empty?
        '《' + @name + '》'
      else
        '《' + @japanese_name + '/' + @name + '》'
      end
    end

    def name
      @name
    end

    def output_html
      '<li>' + @quantity.to_s + 'x ' + full_name + '</li>' 
    end
  end
end

Jekyll::Hooks.register :posts, :post_render do |post|
  doc = Nokogiri::HTML(post.output)
  db = MtgList::Database.new("_additional_data/mtgjson")

  p 'compiling ' + post.data['title']

  doc.search('pre/code[class="language-mtg-pool"]').each do |code|
    pool = MtgList::Pool.new(code.inner_html, db)
    div_pool = Nokogiri::XML::Node::new('div', doc)
    div_pool['class'] = 'mtg-pool'
    div_pool.inner_html = pool.output_html
    pre = code.parent
    pre.add_next_sibling(div_pool)
    pre.remove 
  end
  doc.search('pre/code[class="language-mtg-deck"]').each do |code|
    pool = MtgList::Deck.new(code.inner_html, db)
    div_deck = Nokogiri::XML::Node::new('div', doc)
    div_deck['class'] = 'mtg-deck'
    div_deck.inner_html = pool.output_html
    pre = code.parent
    pre.add_next_sibling(div_deck)
    pre.remove 
  end
  post.output = doc.to_html(save_with: 0)
end
