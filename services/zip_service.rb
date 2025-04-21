require 'zip'

module ZipService
  def unzip(sync_path, zip_data)
    Tempfile.create(%w[remote_files .zip]) do |tmp_zip|
      tmp_zip.binmode
      tmp_zip.write(zip_data)
      tmp_zip.rewind
    
      Zip::File.open(tmp_zip.path) do |zip_file|
        zip_file.each do |entry|
          path = File.join(Dir.home + "/" + sync_path + "/", entry.name)
          FileUtils.mkdir_p(File.dirname(path))
          entry.extract(path) { true }
        end
      end
    end
  end
end