Shindo.tests('Cifrado | SwiftClient#head') do

  obj1 = create_bin_payload 1
  clean_object = clean_object_name(obj1)
  tests 'head object' do
    test "object #{clean_object} headers available" do
      client.upload test_container_name, obj1
      client.head(test_container_name, obj1).is_a?(Hash)
    end
    test 'head invalid object' do
      client.head(test_container_name, SecureRandom.hex).nil?
    end
  end
  tests 'head account' do
    test "head account bytes" do
      !client.head['X-Account-Bytes-Used'].nil? 
    end
    test "head account bytes" do
      client.head['X-Account-Object-Count'].to_i >= 0
    end
  end
  tests 'head container' do
    test "head container bytes" do
      !client.head(test_container_name)['X-Container-Bytes-Used'].nil? 
    end
    test "head container bytes" do
      client.head(test_container_name)['X-Container-Object-Count'].to_i >= 0
    end
    test 'head invalid container' do
      client.head(SecureRandom.hex).nil?
    end
  end 

end
