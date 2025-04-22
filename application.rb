require "bundler/setup"
require "json"
require "rufus-scheduler"
require_relative "file_sync"

class FileSyncApplication
  def initialize
    @scheduler = nil
    @sync_status = "off"
  end

  def call(env)
    request = Rack::Request.new(env)
    path = request.path_info

    case path
    when "/start-sync"
      start_sync(request)
    when "/stop-sync"
      stop_sync
    when "/sync-status"
      sync_status
    end
  end

  private

  def create_schedular
    Rufus::Scheduler.new
  end

  def start_sync(request)
    puts "Running sync task..."
    auth_token = request.env["HTTP_AUTHORIZATION"]
    sync_path = JSON.parse(request.body.read)["folderPath"]
    sync_task = FileSync.new(auth_token, sync_path)
    sync_task.run
    @sync_status = "on"
    start_scheduler(auth_token, sync_path)
    [201, {}, ["Sync successful"]]
  end

  def stop_sync
    stop_scheduler
    @sync_status = "off"
    [200, {}, ["Sync successfully stopped"]]
  end

  def sync_status
    [200, {}, [{ syncStatus: @sync_status }.to_json]]
  end

  def start_scheduler(auth_token, sync_path)
    @scheduler = create_schedular
    @scheduler&.every "5s" do
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
