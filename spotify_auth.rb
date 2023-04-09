class SpotfiyAuth
  def self.authenticate client_id: nil, client_secret: nil
    RSpotify.authenticate(client_id,client_secret)
  end
end