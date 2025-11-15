require "spec"
require "../src/aisweeper"

def random_alphanumeric(length : UInt8)
  charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  Array.new(length) { charset.split("").sample }.join
end

def fixtures_path
  Path["./spec/fixtures/files"]
end

def with_temp_fixture(fixture_name : String, &)
  with_tempdir do |tempdir|
    fixture_file = fixtures_path.join(fixture_name)
    temp_fixture_file = tempdir.join(fixture_name)

    FileUtils.mkdir_p(temp_fixture_file.dirname)
    FileUtils.cp(fixture_file, temp_fixture_file)

    yield temp_fixture_file, tempdir
  end
end

def with_tempdir(&)
  today = Time.local.to_s("%Y%m%d")
  temp_directory_name = "d#{today}-#{random_alphanumeric(5)}"
  temp_path = Path[Dir.tempdir].join(temp_directory_name)
  Dir.mkdir(temp_path)
  yield temp_path
ensure
  FileUtils.rm_rf temp_path if !temp_path.nil? && Dir.exists?(temp_path)
end
