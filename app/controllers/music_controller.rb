class MusicController < ApplicationController
  include MusicHelper

  def get_music
    results = get_music_from_all_sources music_params
    render :json => results, :status => :ok
  end
  
  def test
  end  
  
  private

  def music_params
    params.permit(:query, :sound_source, :auth_token, :force_flag)
  end


end
