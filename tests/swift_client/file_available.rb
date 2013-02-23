Shindo.tests('Cifrado | SwiftClient#file_available?') do

  obj1 = create_bin_payload 1
  clean_object = clean_object_name(obj1)
  tests 'success' do
    test "object #{clean_object} available in #{test_container_name}" do
      client.upload test_container_name, obj1
      client.file_available? test_container_name, clean_object
    end
    test "object #{obj1} available in #{test_container_name}" do
      client.upload test_container_name, obj1
      !client.file_available? test_container_name, obj1
    end
  end 
  tests 'failures' do
    container = SecureRandom.hex
    test "object #{obj1} not available in #{container}" do
      !(client.file_available? container, clean_object)
    end
    test "object #{container} not available in #{test_container_name}" do
      !(client.file_available? test_container_name, container)
    end
  end 

end
