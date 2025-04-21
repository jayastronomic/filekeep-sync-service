require 'bundler/setup' 
require 'json'
require 'rufus-scheduler'
require_relative "file_sync"

class FileSyncApplication

  def initialize
    @scheduler = nil
  end

  def create_schedular
    Rufus::Scheduler.new
  end

  def call(env)
    request = Rack::Request.new(env)
    request_method = request.env["REQUEST_METHOD"]
    if request_method == "POST"
      puts "Running sync task..."
      auth_token = request.env["HTTP_AUTHORIZATION"]
      sync_path = JSON.parse(request.body.read)["folderPath"]
      sync_task = FileSync.new(auth_token, sync_path)
      sync_task.run
      start_scheduler(auth_token, sync_path)
      [201, {}, ["Sync successful"]]
    elsif request_method == "GET"
      stop_scheduler
      [200, {}, ["Sync successfully stopped"]]
    end
  end 

  def start_scheduler(auth_token, sync_path)
    @scheduler = create_schedular
    @scheduler&.every '1m' do
      puts "Running sync task..."
      sync_task = FileSync.new(auth_token, sync_path)
      sync_task.run
    end
  end

  def stop_scheduler
    puts "Stopping sync task..."
    @scheduler&.shutdown
  end
end
