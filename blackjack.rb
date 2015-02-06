require_relative 'main'

class Card
  attr_reader :suit, :face_value, :cards
  def initialize(face_value, suit)
    @face_value = face_value
    @suit = suit
  end

  def to_s
    "#{face_value} of #{suit}"
  end
end

class Deck
  attr_accessor :cards

  def initialize
    @cards = []
  end

  def create_deck
    ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"].each do |face_value|
      ["Clubs", "Diamonds", "Hearts", "Spades"].each do |suit|
        cards << Card.new(face_value, suit)
      end
    end
    scramble!
  end

  def scramble!
    cards.shuffle!
  end

  def deal_one_card
    cards.pop
  end
end

def total(player_or_dealer)
  total = 0
  face_values = player_or_dealer.map {|card| card.face_value }
  face_values.each do |value|
    if value == "A"
      total += 11
    else
      total += (value.to_i == 0 ? 10 : value.to_i)
    end
  end
  total
end