class QuizController < ApplicationController
  include QuizHelper
  skip_before_action :verify_authenticity_token

  GENRE_LIST = ['Rock', 'Electronic', 'Bollywood', 'pop', 'Country', 'Rap', 'Latin']

  def get_question
    render :json => get_next_question(question_params), :status => :ok
  end

  def start_new_game
    render :json => new_game(new_game_params), :status => :ok
  end

  def get_genres
    render :json => {:genres => GENRE_LIST}, :status => :ok
  end

  def get_final_scores
    render :json => final_scores(final_scores_params), :status => :ok
  end

  private

  def question_params
    params.permit(:user_ids, :previous_scores, :game_id)
  end

  def new_game_params
    params.permit(:user_name, :genre)
  end

  def final_scores_params
    params.permit(:user_ids, :game_id)
  end
end
