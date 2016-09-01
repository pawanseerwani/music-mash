module ChatHelper
  def start_game_helper(params)
    genre = params[:genre]
    user_name = params[:user_name]
    redis_genre = $redis.get(genre)
    if redis_genre.present?
      $redis.set(genre, "redis_genre")
    else 
    end
  end
end
