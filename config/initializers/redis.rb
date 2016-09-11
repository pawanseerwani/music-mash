redis = Redis.new(:host => "localhost", :port => "6379")
$redis = Redis::Namespace.new(:new_projects, :redis => redis)
