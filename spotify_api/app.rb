require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'byebug'
require 'sinatra'
require 'erb'
require 'figaro'
require 'rspotify'
require 'omniauth'
require 'omniauth-oauth2'
require 'omniauth-spotify'
require './spotify_auth'
require './spotify_api'

Figaro.application = Figaro::Application.new(environment: "development", path: "config/application.yml")
Figaro.application.load

configure do
  set :client_id, ENV['SPOTIFY_CLIENT_ID']
  set :client_secret, ENV['SPOTIFY_CLIENT_SECRET']
  set :redirect_url, settings.environment == :development ? ENV['SPOTIFY_LOCAL_REDIRECT_URI'] : ENV['SPOTIFY_REDIRECT_URI']
  end

use Rack::Session::Cookie
use Rack::Protection::AuthenticityToken

use OmniAuth::Builder do
  provider :spotify, ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'], scope: 'user-read-email playlist-modify-public user-library-read user-library-modify'
end

# ROUTES

post '/auth/spotify/callback' do
  byebug
  # @query = params[:query]
  # auth = request.env['omniauth.auth']
end

get '/' do
  byebug
end

post '/auth/failure' do
end
