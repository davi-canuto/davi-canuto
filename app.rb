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
  scope = 'user-read-currently-playing user-read-recently-played'

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

    redirect '/my-current-track'
  else
    status 401
    "Failed to authenticate with Spotify"
  end
end

get '/now-playing' do
  @svg = make_attrs(data: session['now_playing'])

  erb :spotify
end

get '/my-current-track' do
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
    session['now_playing'] = {
      action: :my_current_track,
      data: JSON.parse(res.body)
    }
    redirect '/now-playing'
  elsif status_code == 204
    redirect '/my-recently-play'
  else
    @error = {
      status: status_code,
      message: res.message
    }

    erb :not_playing
  end
end

get '/my-recently-play' do
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
    session['now_playing'] = {
      action: :my_recently_play,
      data: JSON.parse(res.body)
    }
    redirect '/now-playing'
  else
    @error = {
      status: status_code,
      message: res.message
    }

    erb :not_playing
  end
end

def load_image_b64(url)
  response = Net::HTTP.get_response(URI(url))
  Base64.encode64(response.body).gsub("\n", "")
end

def make_attrs data: {}
  if data.empty?
    return { }
  end

  item = data["item"]
  @img = load_image_b64(item["album"]["images"][1]["url"])
  @artist_name = item["artists"][0]["name"]
  @song_name = item["name"]
  @url = item["external_urls"]["spotify"]

  return {
    img: @img,
    artist_name: @artist_name,
    song_name: @song_name,
    url: @url,
    item: item
  }
end