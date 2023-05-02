require 'uri'
class SpotifyApi
  def initialize(token)
    @token = token
    @base_url = 'https://api.spotify.com/v1'
  end

  def current_track
    begin
      res = get("/me/player/currently-playing")
      status_code = res.code.to_i
      res_parsed = JSON.parse(res.body) if res.body
      res_track = self.get_track(res_parsed["item"]["id"]) if res_parsed

      return {
        action: :current_track,
        data: res_parsed,
        track: JSON.parse(res_track.body),
        status_code: status_code
      } if status_code == 200

      return {
        action: :current_track,
        status_code: status_code
      } if status_code == 204

      return {
        message: res.message,
        status_code: status_code
      }
    rescue => ex
      puts ex.message
    end
  end

  def latest_track
    begin
      res = get("/me/player/recently-played?limit=10")
      status_code = res.code.to_i

      if status_code == 200
        track_id = JSON.parse(res.body)["items"].sample["track"]["id"]
        new_res = self.get_track(track_id)

        return {
          action: :latest_track,
          data: JSON.parse(new_res.body),
          status_code: status_code
        }
      end

      return {
        action: :latest_track,
        message: res.message,
        status_code: status_code
      }
    rescue => ex
      puts ex.message
    end
  end

  def get_track track_id
    begin
      res = get("/tracks/#{track_id}")
      status_code = res.code.to_i

      return res if status_code == 200
    rescue => ex
      puts ex.message
    end
  end

  private
   def get url
     uri = URI(@base_url + url)
     req = Net::HTTP::Get.new(uri)
     req['Authorization'] = "Bearer #{@token}"

     res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
       http.request(req)
     end
     res
   end
end
