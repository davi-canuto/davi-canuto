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

configure do
  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true

  use Rack::CommonLogger, file
end

enable :sessions
set :session_secret, ENV['SESSION_SECRET']
$enviroment = settings.environment

# HELPERS

def load_image_b64(url)
  response = Net::HTTP.get_response(URI(url))
  Base64.encode64(response.body).gsub("\n", "")
end

def make_attrs data: {}
  if data.empty?
    return {}
  end

  item = if data[:action] == :current_track
    data[:data]["item"]
  else
    data[:data]
  end

  image_data = Base64.decode64(load_image_b64(item["album"]["images"][1]["url"]))
  File.open('public/assets/album.jpg', 'wb') do |f|
    f.write image_data
  end

  @artist_name = item["artists"][0]["name"]
  @song_name = item["name"]
  @url = item["external_urls"]["spotify"]

  return {
    artist_name: @artist_name,
    song_name: @song_name,
    url: @url,
    item: item
  }
end

# ROUTES

get '/' do
  redirect_uri = $enviroment == :development ? 'http://localhost:9292/callback' : 'https://github.com/davi-canuto'
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

    redirect '/now-playing'
  else
    status 401
    "Failed to authenticate with Spotify"
  end
end

get '/now-playing' do
  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = spotify_auth_api.refresh_tokens(session['refresh_token'])
  token = tokens['access_token']

  spotify_api = SpotifyApi.new(token)
  _response = spotify_api.current_track
  if _response[:status_code] == 204
    _response = spotify_api.latest_track
  end
  response = make_attrs(data: _response)
  @song_name = response[:song_name]
  @artist_name = response[:artist_name]
  @url = response[:url]

  erb :spotify
end