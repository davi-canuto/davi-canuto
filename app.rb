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
  scope = 'user-read-private user-read-email user-top-read user-read-currently-playing user-read-playback-state'

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

    redirect '/my_recently_play'
  else
    status 401
    "Failed to authenticate with Spotify"
  end
end

get '/my_current_track' do
  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = spotify_auth_api.refresh_tokens(session['refresh_token'])
  token = tokens['access_token']

  uri = URI('https://api.spotify.com/v1/me/player/currently-playing')
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(req)
  end
  status_code = res.code.to_i

  if status_code == 200
    JSON.parse(res.body)
  else
    status status_code
    res.message
  end
end

get '/my_recently_play' do
  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = spotify_auth_api.refresh_tokens(session['refresh_token'])
  token = tokens['access_token']

  uri = URI('https://api.spotify.com/v1/me/player/recently-played?limit=10')
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(req)
  end
  status_code = res.code.to_i

  if status_code == 200
    byebug
    JSON.parse(res.body)
  else
    status status_code
    res.message
  end
end