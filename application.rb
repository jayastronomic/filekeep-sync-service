require 'json'
require_relative "file_sync"

class FileSyncApplication
  def call(env) 
    request = Rack::Request.new(env)
    auth_token = request.env["HTTP_AUTHORIZATION"]
    sync_path = JSON.parse(request.body.read)["folderPath"]
    file_sync = FileSync.new(auth_token, sync_path)
    file_sync.run
    [201, {}, ["Sync successful"]]
  end 
end
