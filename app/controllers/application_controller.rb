class ApplicationController < ActionController::API
  require 'net/http'
  @@remote_api = "http://localhost:8080/api/v1/sync"

  def sync
    token = request.headers['Authorization']
    sync_path = params[:folder_path]
    files = load_files_from_directory(Dir.home + "/" + sync_path)
    process_files(files, sync_path, token)
  end

  private 
  def load_files_from_directory(path)
    # Ensure the path exists
    return unless File.directory?(path)

    files = []
  
    # Traverse all items (files and subdirectories) in the given directory
    Dir.foreach(path) do |item|
      # Skip the current (.) and parent (..) directory references
      next if item.start_with?('.')

      # Build the full path of the item
      full_item_path = File.join(path, item)
  
      # If it's a directory, recurse into it
      if File.directory?(full_item_path)
        files += load_files_from_directory(full_item_path)  # Recursively load subdirectories
      else
        # log loaded file
        puts "Loaded file: #{full_item_path}"

        files << {
        file_name: File.basename(full_item_path),
        file_path: full_item_path,
        }
        puts files
      end
    end

    return files
  end

  def process_files(files, sync_path, token)
    boundary = "----RubyMultipartPost#{rand(100000)}"
    body = []
    files.each do |file|
      file_path = file[:file_path]
      file_name = file[:file_name]
      file_content_type = MIME::Types.type_for(file_name).first.content_type
      file_path_name = file_path.delete_prefix(Dir.home + "/" + sync_path + "/")

      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"files\"; filename=\"#{file_path_name}\"\r\n"
      body << "Content-Type: #{file_content_type}\r\n"
      body << "\r\n"
      body << File.read(file_path)  # Attach the file content
      body << "\r\n"
    end

    #Adding a final boundary
    body << "--#{boundary}--\r\n"
    call_remote_api(body, boundary, token)
  end

  def call_remote_api(body, boundary, token)
    uri = URI.parse(@@remote_api)
    #Create the HTTP request
    request = Net::HTTP::Post.new(uri.path, {
      'Content-Type' => "multipart/form-data; boundary=#{boundary}",
      'Authorization' => token
    })

    request.body = body.join
    puts "processing files".colorize(:green)

    #Perform the HTTP request
    begin
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      # Handle the response from the API
      if response.code.to_i == 200
        puts response.body
      else
        puts "Error processing files: #{response.message}"
      end
    rescue => e
      puts "Error sending files batch: #{e.message}"
    end
  end
end
