class SpotifyAuthApi
  def initialize(client_id, client_secret)
    @client_id = client_id
    @client_secret = client_secret
  end

  def get_token
    grant = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    uri = URI.parse('https://accounts.spotify.com/api/token')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = { 'Authorization' => "Basic #{grant}" }
    req = Net::HTTP::Post.new(uri.request_uri, headers)
    data = { 'grant_type' => 'refresh_token',
             'refresh_token' => ENV['SPOTIFY_REFRESH_TOKEN'] }
    req.set_form_data(data)

    res = http.request(req)
    if res.kind_of? Net::HTTPSuccess
      json = JSON.parse(res.body)
      json['access_token']
    end
  end
end
