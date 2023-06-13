require "fileutils"
require "zip"

# largely taken from https://raw.githubusercontent.com/rubyzip/rubyzip/9d891f7353e66052283562d3e252fe380bb4b199/samples/example_recursive.rb
class PackageZipper
  EXCLUDE_LIST = %w[. .. .publish.yml .invoker_data]
  attr_reader :source_dir, :package_path

  def initialize(source_dir:, package_path:)
    @source_dir = source_dir
    @package_path = package_path
  end

  def zip!
    FileUtils.rm(package_path) if File.exist?(package_path)
    entries = Dir.entries(source_dir) - EXCLUDE_LIST

    Zip::File.open(package_path, Zip::File::CREATE) do |zipfile|
      write_entries entries, '', zipfile
    end
  end

  private

  def write_entries(entries, path, zipfile)
    entries.each do |e|
      zipfile_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(source_dir, zipfile_path)

      if File.directory? disk_file_path
        recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
      else
        put_into_archive(disk_file_path, zipfile, zipfile_path)
      end
    end
  end

  def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
    zipfile.mkdir zipfile_path
    subdir = Dir.entries(disk_file_path) - EXCLUDE_LIST
    write_entries subdir, zipfile_path, zipfile
  end

  def put_into_archive(disk_file_path, zipfile, zipfile_path)
    zipfile.add(zipfile_path, disk_file_path)
  end  
end