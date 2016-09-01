module QuizHelper
  require 'soundcloud'

  def start_game_helper params
    new_game params
  end

  def new_game params
    return {:status => 404, :message => "Username not provided"} if params[:user_name].nil?
    user1_name, user1_id = user_waiting params[:genre]
    if user1_name.present?
      puts "I am the second user with params: #{params}. First being #{user1_name}"
      game_id = get_game_redis_key
      redis_key = "quiz_#{game_id}"
      scores_hash = {}
      [1,2].map{|x| scores_hash[x] = 0}
      users_data = {1 => {name: user1_name, score: 0, self_user_id: user1_id}, 2 => {name: params[:user_name], score: 0, self_user_id: params[:self_user_id]}}
      $redis.hmset(redis_key, :genre, params[:genre], :question_count, 0, :users_data, users_data)
      output_message = {:status => 200, :message => "Game started!", :users_data => users_data, :game_id => game_id, :genre => params[:genre]}
    else
      puts "I am the first user with params: #{params}"
      redis_key = "waiting_username_for_#{params[:genre]}"
      $redis.set(redis_key, params[:user_name])
      redis_key = "waiting_user_for_id_#{params[:genre]}"
      $redis.set(redis_key, params[:self_user_id])
      output_message = {:status => 100, :message => "User enqueued for the next game", :users_data => {1 => params[:user_name]}}
    end
    output_message
  end

  def get_next_question params
    redis_key = "quiz_#{params[:game_id]}"
    result = $redis.hgetall(redis_key)
    if params[:question_count].to_s.to_i < result["question_count"].to_s.to_i
      question,flag = nil,false
    else
      selected_genre = result["genre"]
      update_scores(params)
      question,flag = create_question(selected_genre, redis_key, params[:game_id]), true
    end
    [question,flag]
  end

  def update_scores params
    redis_key = "quiz_#{params[:game_id]}"
    result = $redis.hgetall(redis_key).symbolize_keys
    result[:users_data] = eval(result[:users_data])
    match  = result[:users_data].select{|key, hash| hash[:self_user_id] == params[:self_user_id] }.first
    hash_index = match.first
    result[:users_data][hash_index][:score] += 1 if params[:correctly_answered]
    $redis.hmset(redis_key, :users_data, result[:users_data], :question_count, params[:question_count].to_i + 1)
  end

  def get_final_scores params
    redis_key = "quiz_#{params[:game_id]}"
    result = eval($redis.hgetall(redis_key)["users_data"]).merge({game_id: params[:game_id]})
    flag = (params[:question_count].to_s == result["question_count"].to_s ) ? false : true
    [result, flag]
  end

  private

  def get_user_ids user_ids
    user_ids.split(',') rescue []
  end

  def create_question selected_genre, redis_key, game_id
    # add cache
    selected_genre = selected_genre.strip
    cache_random_number = rand(50)
    cache_key = "#{selected_genre}_#{cache_random_number}"
    cache_output = JSON.parse(File.read("#{Rails.root}/private/#{selected_genre}.json"))[cache_random_number.to_s]
    # cache_output = Rails.cache.fetch(cache_key) do
    #   # end cache

    #   client_id = '324bae5b94e95f9afa812ce3610972f5'
    #   index = rand(4)
    #   answer = index
    #   question = "Guess the song!"
    #   begin
    #     tracks = get_four_tracks(selected_genre, client_id)
    #     options = tracks.map{|t| t.title}
    #     result = true
    #     options.each{|o| result = (result & o.ascii_only?)}
    #     raise "Options Not Having Ascii Characters" if !result
    #     song = tracks[index].stream_url.to_s + "?client_id=" + client_id
    #     waveform = tracks[index].waveform_url
    #   rescue
    #     retry
    #   end
    #   output = {:question => question, :answer => index, :options => options, :song => song, :waveform => waveform}.to_json
    # end
    result = $redis.hgetall(redis_key).symbolize_keys
    return  cache_output.merge({:users_data => eval(result[:users_data]), question_count: result[:question_count], game_id: game_id, game_data: result}).with_indifferent_access
  end

  def get_four_tracks selected_genre, client_id
    random_number = rand(10000)
    client = Soundcloud.new(:client_id => client_id, :client_secret =>'ffe7cbb2c397bb6b2a6f2c98cb9bf18b')
    tracks = client.get('/tracks', :genres => selected_genre, :order => 'created_at', :limit => 4, :offset => random_number, :licence => 'cc-by-sa')
  end

  def user_waiting genre
    redis_key = "waiting_username_for_#{genre}"
    user_name = $redis.get(redis_key)
    $redis.del(redis_key)

    redis_key = "waiting_user_for_id_#{genre}"
    self_user_id = $redis.get(redis_key)
    $redis.del(redis_key)

    return user_name, self_user_id
  end

  def get_game_redis_key
    last_game_id = $redis.get("max_game_id").to_i
    $redis.set("max_game_id", last_game_id + 1)
    last_game_id + 1
  end

  ###########################################################

  def create_question_cache
    # add cache
    genres = QuizController::GENRE_LIST
    genre_cache = {}
    genres.each do |selected_genre|
      genre_cache[selected_genre] = {}
      50.times do |cache_random_number|
        cache_key = "#{selected_genre}_#{cache_random_number}"
        next if File.exist?("private/#{cache_key}.json")
        puts cache_key
        #cache_output = Rails.cache.fetch(cache_key) do
        # end cache

        client_id = '324bae5b94e95f9afa812ce3610972f5'
        index = rand(4)
        answer = index
        question = "Guess the song!"
        begin
          tracks = get_four_tracks(selected_genre, client_id)
          options = tracks.map{|t| t.title}
          result = true
          options.each{|o| result = (result & o.ascii_only?)}
          raise "Options Not Having Ascii Characters" if !result
          song = tracks[index].stream_url.to_s + "?client_id=" + client_id
          waveform = tracks[index].waveform_url
        rescue
          retry
        end
        output = {:question => question, :answer => index, :options => options, :song => song, :waveform => waveform}
        genre_cache[selected_genre][cache_random_number] = output
        #end
      end
      f = File.new("#{Rails.root}/private/#{selected_genre}.json", "wb")
      f.write(genre_cache[selected_genre].to_json)
      f.close
    end
  end

end
