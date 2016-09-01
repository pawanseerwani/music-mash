module MusicHelper
  require 'soundcloud'

  def get_music_from_all_sources params
    cache_key = "get_music_#{params[:query]}"
    force_flag = params[:force_flag]
    results = Rails.cache.fetch(cache_key, force: force_flag) do
      results = []
      results += get_music_from_spotify params[:query] if params[:sound_source].nil? || params[:sound_source] == "spotify"
      results += get_music_from_soundcloud params[:query] if params[:sound_source].nil? || params[:sound_source] == "soundcloud"
      results.to_json
    end
    results
  end

  def get_music_from_soundcloud q
    client_id = '324bae5b94e95f9afa812ce3610972f5'
    # create a client object with your app credentials
    client = Soundcloud.new(:client_id => client_id, :client_secret =>'ffe7cbb2c397bb6b2a6f2c98cb9bf18b')
    # find all sounds of buskers licensed under 'creative commons share alike'
    tracks = client.get('/tracks', :q => q, :licence => 'cc-by-sa')
    response = parse_soundcloud_response(tracks, client_id)
    response
  end

  def get_music_from_spotify q
    url = "https://api.spotify.com/v1/search?q=#{q}&type=track"
    uri = URI.parse(URI.encode(url))
    response = JSON.parse(Net::HTTP.get(uri), :symbolize_names => true) rescue []
    response = parse_spotify_response(response) if response.present?
    response
  end

  private

  def parse_soundcloud_response response, client_id
    output = []
    response = response.sort_by{|e| -1 *(e[:likes_count] + 2*e[:reposts_count])} rescue []
    response.each do |item|
      item_hash = {
        id: 'soundcloud_' + item[:id].to_s,
        name: item[:title],
        music_url: item[:stream_url].to_s + "?client_id=" + client_id,
        image_url: item[:artwork_url],
        source_id: "",
        source: 'soundcloud',
        duration: item[:duration],
        uri: "",
        download_url: item[:download_url],
        popularity: item[:likes_count] + 2*item[:reposts_count]
      }
      output << item_hash
    end
    output
  end

  def parse_spotify_response response
    output = []
    items = response[:tracks][:items].sort_by{|e| -1 * e[:popularity] } rescue []
    items.each do |item|
      item_hash = {
        id: 'spotify_' + item[:id],
        name: item[:name],
        music_url: item[:preview_url],
        image_url: (item[:album][:images].second[:url] rescue nil),
        artist: (item[:artists].map{ |x| x[:name] }.join(', ') rescue ""),
        source_id: item[:id],
        source: 'spotify',
        duration: 30,
        uri: item[:uri],
        popularity: item[:popularity],
      }
      output.push(item_hash)
    end
    output
  end

end
