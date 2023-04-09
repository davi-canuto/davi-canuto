class SpotifyApi
  def initialize client_id, client_secret
    @client_id = client_id
    @client_secret = client_secret
    @spotify_username = 12163995996.to_s
    @user = RSpotify::User.find(@spotify_username)
  end

  def playlists
    # get_me.
  end
end