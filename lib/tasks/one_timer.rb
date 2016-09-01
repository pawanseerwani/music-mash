namespace :one_timer do
  include MusicHelper

  desc "build_cache"
  task :build_cache => :environment do
    ('a'..'zzz').to_a.each do |q|
    	puts "query => #{q}"
      params = {:query => q, :force_flag => false}
      get_music_from_all_sources params
    end
  end

end
