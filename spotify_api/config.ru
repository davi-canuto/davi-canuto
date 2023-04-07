
require 'sinatra'
require 'figaro'
require 'spotify'

Figaro.application.load

configure do
  set :spotify_client_id, ENV['SPOTIFY_CLIENT_ID']
  set :spotify_client_secret, ENV['SPOTIFY_CLIENT_SECRET']
end

run Sinatra::Application