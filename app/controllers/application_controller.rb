class ApplicationController < ActionController::API
    @@root_file_path = "/mnt/host-files/"
    def sync 
        sync_path = params[:folder_path]
       contents = Dir.entries(sync_path).reject { |entry| entry.start_with?(".") }
       render json: { folder_path: "synced"}
    end
end
