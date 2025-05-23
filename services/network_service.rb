require 'net/http'
require 'colorize'

module NetworkService
  def post(body, headers)
    uri = URI.parse("http://localhost:8080/api/v1/sync")
    request = Net::HTTP::Post.new(uri.path || "/", headers)
    request.body = body
    begin
      Net::HTTP.start(uri.hostname || "localhost", uri.port) do |http|
        http.request(request)
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end

  def get_zipped_files(headers)
    uri = URI.parse("http://localhost:8080/api/v1/sync")
    request = Net::HTTP::Get.new(uri.path || "/", headers)
    begin
      puts "Getting zipped files: /GET http://localhost:8080/api/v1/sync...".colorize(:blue)
      Net::HTTP.start(uri.hostname || "localhost", uri.port) do |http|
        http.request(request)
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end
end