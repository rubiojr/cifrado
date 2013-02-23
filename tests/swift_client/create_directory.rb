Shindo.tests('Cifrado | SwiftClient#create_directory') do

  tests '#create_directory' do
    name = SecureRandom.hex
    dir = client.create_directory name
    test 'is a Fog::Storage::OpenStack::Directory' do
      dir.is_a? Fog::Storage::OpenStack::Directory
    end
    test "dir name is #{name}" do
      dir.key == name 
    end
  end

end
