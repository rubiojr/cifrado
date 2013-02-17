require 'cifrado'
require 'yaml'
require 'securerandom'
require 'fileutils'
require 'digest/md5'

include Cifrado

def client
  conf = YAML.load_file File.expand_path("~/.cifradorc")
  client = SwiftClient.new  :username => conf[:username],
                            :api_key  => conf[:password],
                            :auth_url => conf[:auth_url],
                            :connection_options => { :ssl_verify_peer => false }
end

def test_container
  @container ||= begin
    client.service.directories.create :key => 'cifrado-tests'
  end
end

# Size in KB
def create_bin_payload size
  tmp_file = "/tmp/cifrado-test-payload-#{SecureRandom.hex}"
  `dd if=/dev/zero of=#{tmp_file} bs=1K count=#{size} > /dev/null 2>&1`
  raise "Error creating #{size}MB binary payload" unless $? == 0
  tmp_file
end

def clean_test_payloads
  Dir["/tmp/cifrado-test-payload-*"].each do |f|
    File.delete f
  end
end

def passphrase
  'foobar'
end

def cleanup
  clean_test_payloads
  Dir["/tmp/cifrado*"].each { |f| FileUtils.rm_rf f }
  dir = client.service.directories.get('cifrado-tests')
  if dir
    dir.files.each do |f|
      f.destroy
    end
    dir.destroy
  end
end

def tmpfile
  "/tmp/cifrado-tests-#{SecureRandom.hex}"
end

at_exit do
  puts "Cleaning up..."
  cleanup
end
