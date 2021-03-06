require 'rubygems'
require 'sinatra'

# set :sessions, true

use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :secret => 'your_secret'

BLACKJACK = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

helpers do 
  def calculate_total(cards)
    card_array = cards.map {|card| card[1]}
    total = 0
    card_array.each do |card|
      if card == 'A'
        total += 11
      else
        total += card.to_i == 0 ? 10 : card.to_i
      end
    end
    card_array.select {|card| card == "A"}.count.times do
      break if total <= 21
      total -= 11
    end
    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def play_again
    @play_again = true
    @show_hit_or_stay_buttons = false
  end

  def winner!(msg)
    session[:player_pot] += session[:player_bet]
    play_again
    @winner = "<strong>#{session[:player_name]} wins</strong> #{msg}"
  end

  def loser!(msg)
    session[:player_pot] -= session[:player_bet]
    play_again
    @loser = "<strong>#{session[:player_name]} loses</strong> #{msg}"
  end

  def tie!(msg)
    play_again
    @winner = "<strong>Its's a tie!</strong> #{msg}"
  end
end

before do 
  @show_hit_or_stay_buttons = true
end

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do 
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :new_player
end

post '/new_player' do 
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do 
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  params[:bet_amount].to_i
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet"
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})"
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do 
  session[:turn] = session[:player_name]
  #deck
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle! 
  
  #deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  erb :game
end

post '/game/player/hit' do 
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK
    winner!("#{session[:player_name]} hit Blackjack!")
    
  elsif player_total > BLACKJACK
    loser!("looks like, #{session[:player_name]} busted at #{player_total}.")
  end
  erb :game, layout: false
end

post '/game/player/stay' do 
  @success = "#{session[:player_name]} has chosen to stay"
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do 
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false
  
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK
    loser!("dealer hit Blackjack.")
  elsif dealer_total > BLACKJACK
    winner!("dealer busted! at #{dealer_total}")
  elsif dealer_total >= DEALER_MIN_HIT
    # dealer stays
    redirect '/game/compare'
  else
    # dealer hits
    @show_dealer_hit_button = true
  end

  erb :game, layout: false
end

post '/game/dealer/hit' do 
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false 
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}")
  elsif player_total > dealer
    winner!("#{session[:player_name]} stayed at #{player_total} and the dealer stayed at #{dealer_total}")
  else
    tie!("both #{session[:player_name]} and #{session[:dealer]} stayed at #{player_total}")
  end

  erb :game, layout: false
end

get '/game_over' do 
  erb :game_over
end