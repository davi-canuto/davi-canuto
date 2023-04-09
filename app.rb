require 'securerandom'
require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'byebug'
require 'sinatra'
require 'erb'
require 'dotenv/load'

require_relative 'models/spotify_auth_api'
require_relative 'models/spotify_api'

def escape_url(url)
  URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def get_spotify_auth_url
  client_id = ENV['SPOTIFY_CLIENT_ID']
  redirect_uri = escape_url("#{request.base_url}/auth/callback/spotify")
  scopes = ['user-read-currently-playing', 'user-read-email']

  "https://accounts.spotify.com/authorize?client_id=" +
    "#{client_id}&response_type=code&redirect_uri=" +
    "#{redirect_uri}&scope=#{scopes.join('%20')}"
end

configure do
  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true

  use Rack::CommonLogger, file
end

enable :sessions
set :session_secret, ENV['SESSION_SECRET']

# ROUTES

get '/' do
  redirect_uri = 'http://localhost:9292/callback'
  state = SecureRandom.hex(16)
  scope = 'user-read-private user-read-email'

  uri = URI('https://accounts.spotify.com/authorize')

  uri.query = URI.encode_www_form({
    response_type: 'code',
    client_id: ENV['SPOTIFY_CLIENT_ID'],
    scope: scope,
    redirect_uri: redirect_uri,
    state: state
  })

  redirect uri.to_s
end

# Callback for Spotify OAuth authentication.
get '/callback' do
  code = params['code']
  redirect_uri = "#{request.base_url}/callback"

  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = spotify_auth_api.get_tokens(code, redirect_uri)


  if tokens
    session['access_token'] = tokens['access_token']
    session['refresh_token'] = tokens['refresh_token']

    spotify_api = SpotifyApi.new(session['access_token'], logger: logger)

    current_track = spotify_api.get_currently_playing
    puts current_track
  else
    status 401
    "Failed to authenticate with Spotify"
  end
end