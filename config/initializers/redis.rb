redis = Redis.new(:host => "pawans.housing.com", :port => "6379")
$redis = Redis::Namespace.new(:new_projects, :redis => redis)
