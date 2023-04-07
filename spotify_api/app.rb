require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'byebug'
require 'sinatra'
require 'erb'
require 'figaro'
require 'rspotify'
require './spotify_auth'
require './spotify_api'

Figaro.application = Figaro::Application.new(environment: "development", path: "config/application.yml")
Figaro.application.load

configure do
  set :client_id, ENV['SPOTIFY_CLIENT_ID']
  set :client_secret, ENV['SPOTIFY_CLIENT_SECRET']
  set :redirect_url, settings.environment == :development ? ENV['SPOTIFY_LOCAL_REDIRECT_URI'] : ENV['SPOTIFY_REDIRECT_URI']
end

RSpotify.authenticate(settings.client_id,settings.client_secret)

get '/' do
  SpotifyApi.new(settings.client_id,settings.client_secret).playlists
end
