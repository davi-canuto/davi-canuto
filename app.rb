require 'securerandom'
require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'byebug'
require 'sinatra'
require 'dotenv/load'

require_relative 'models/spotify_auth_api'
require_relative 'models/spotify_api'

configure do
  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true

  use Rack::CommonLogger, file
end

$enviroment = settings.environment

# HELPERS

def load_image_base64 url
  uri = URI(url)
  response = Net::HTTP.get_response(uri)

  return Base64.encode64(response.body).gsub("\n", '')
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

  @artist_name = item["artists"][0]["name"]
  @song_name = item["name"]
  @url = item["external_urls"]["spotify"]
  @image = load_image_base64(item["album"]["images"][1]["url"])

  return {
    artist_name: @artist_name,
    song_name: @song_name,
    url: @url,
    image: @image,
    item: item
  }
end

# ROUTES

get '/' do
  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],ENV['SPOTIFY_CLIENT_SECRET'])
  token = spotify_auth_api.get_token

  spotify_api = SpotifyApi.new(token)
  _response = spotify_api.current_track
  if _response[:status_code] == 204
    _response = spotify_api.latest_track
  end
  response = make_attrs(data: _response)
  @song_name = response[:song_name]
  @artist_name = response[:artist_name]
  @url = response[:url]
  @image_url = response[:image]

  content_type :json

  {
    song_name: @song_name,
    artist_name: @artist_name,
    url: @url,
    image: @image
  }.to_json
end