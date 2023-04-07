class SpotifyApi
  def initialize client_id, client_secret
    @client_id = client_id
    @client_secret = client_secret
    @spotify_username = 12163995996.to_s
    SpotfiyAuth.authenticate client_id: @client_id, client_secret: @client_secret
  end

  def get_me
    RSpotify::User.find(@spotify_username)
  end

  def playlists
    byebug
    # get_me.
  end
end