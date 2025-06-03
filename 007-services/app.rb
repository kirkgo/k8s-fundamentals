require "sinatra"

set :bind, "0.0.0.0"
set :port, 4567

get "*" do
  "[v3] Hello, Kubernetes, from #{`hostname`.strip}!\n"
end
