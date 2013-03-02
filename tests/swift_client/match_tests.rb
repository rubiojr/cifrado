Shindo.tests('Cifrado | SwiftClient#match') do

  obj = create_bin_payload 1

  tests("#match") do

    response = client.upload(test_container_name, obj) 

    test "#{test_container_name}/#{obj} available" do
      (client.match obj, test_container_name) == 1
    end
    
    test "#{test_container_name}////#{obj} available" do
      (client.match "///" + obj, test_container_name) == 1
    end
    
    test "#{test_container_name}/#{obj} MD5 changed" do
      File.open(obj, 'w') { |f| f.puts 'foo' }
      (client.match obj, test_container_name) == 2
    end
    
    test "#{test_container_name}/#{obj} not available" do
      clean_test_container
      (client.match obj, test_container_name) == 0
    end

  end

end
