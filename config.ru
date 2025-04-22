require "./application.rb"
require "rack/cors"

use Rack::Cors do
  allow do
    origins "*"
    resource "*",
      headers: :any,
      methods: [:get, :post, :options],
      expose: ["Authorization"]
  end
end

run FileSyncApplication.new
