require 'bundler/setup' 
require 'json'
require 'rufus-scheduler'
require_relative "file_sync"

class FileSyncApplication
  def initialize
    @scheduler = Rufus::Scheduler.new
  end

  def call(env) 
    request = Rack::Request.new(env)
    auth_token = request.env["HTTP_AUTHORIZATION"]
    sync_path = JSON.parse(request.body.read)["folderPath"]
    sync_task = FileSync.new(auth_token, sync_path)
    sync_task.run
    start_scheduler(auth_token, sync_path)
    [201, {}, ["Sync successful"]]
  end 

  def start_scheduler(auth_token, sync_path)
    @scheduler.every '1m' do
      puts "Running sync task..."
      sync_task = FileSync.new(auth_token, sync_path)
      sync_task.run
    end
  end
end
