require "./services/network_service"
require "./services/zip_service"
require "mime/types"
require 'base64'
require 'colorize'

class FileSync
  include NetworkService
  include ZipService

  def initialize(auth_token, sync_path)
    @auth_token = auth_token
    @sync_path = sync_path
  end

  def run
    local_files = load_files_from_directory(Dir.home + '/' + @sync_path)
    puts "found: #{local_files.length} files in #{Dir.home + '/' + @sync_path}".colorize(:blue)
    if local_files.empty?
      sync_remote_to_local
    else
      sync_local_to_remote(local_files)
    end
  end

  private 

  def load_files_from_directory(path)
    return unless File.directory?(path)
  
    local_files = []
  
    Dir.foreach(path) do |item|
      next if item.start_with?('.')
  
      full_item_path = File.join(path, item)
  
      if File.directory?(full_item_path)
        # Recurse into subdirectory
        sub_files = load_files_from_directory(full_item_path)
        local_files += sub_files
  
        # If the subdirectory was empty, still add it as a directory
        if sub_files.empty?
          puts "loaded: #{full_item_path}"
          local_files << {
            file_name: File.basename(full_item_path),
            file_path: full_item_path,
            is_directory: true
          }
        end
      else
        puts "Loaded file: #{full_item_path}"
  
        local_files << {
          file_name: File.basename(full_item_path),
          file_path: full_item_path,
          is_directory: false
        }
      end
    end
    local_files
  end
  

  def sync_local_to_remote(files)
    boundary = "----RubyMultipartPost#{rand(100000)}"
    body = []
  
    files.each do |file|
      file_path = file[:file_path]
      file_name = file[:file_name]
      remote_path = file_path.delete_prefix(Dir.home + "/" + @sync_path + "/")
  
      if file[:is_directory]
        # Handle empty directory: send metadata only
        body << "--#{boundary}\r\n"
        body << "Content-Disposition: form-data; name=\"directories\"\r\n"
        body << "\r\n"
        body << remote_path
        body << "\r\n"
      else
        # Handle regular file
        file_content_type = MIME::Types.type_for(file_name).first&.content_type || "application/octet-stream"
  
        body << "--#{boundary}\r\n"
        body << "Content-Disposition: form-data; name=\"files\"; filename=\"#{remote_path}\"\r\n"
        body << "Content-Type: #{file_content_type}\r\n"
        body << "\r\n"
        body << File.read(file_path)
        body << "\r\n"
      end
    end
  
    body << "--#{boundary}--\r\n"
    call_remote_api(body, boundary)
  end

  def call_remote_api(body, boundary)
    #Perform the HTTP request
    response = post(body.join, {
      'Content-Type' => "multipart/form-data; boundary=#{boundary}",
      'Authorization' => @auth_token
    }) || raise("Response is nil")

    puts response

    sync_remote_to_local if response&.code&.to_i == 201
  end

  def sync_remote_to_local
    puts "syncing remote to local...".colorize(:green)
    #Perform the HTTP request
    response = get_zipped_files({
      'Authorization' => @auth_token
    }) || raise("Response is nil")

    puts response
    # Handle the response from the API
    if response&.code&.to_i == 200
      zip_data = JSON.parse(response.body)["data"]
      save_to_sync_path(zip_data)
    end
  end

  def save_to_sync_path(encoded_zip)
    unzip(@sync_path, Base64.decode64(encoded_zip))
  end
end