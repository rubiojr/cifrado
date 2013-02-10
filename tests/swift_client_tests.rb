Shindo.tests('Cifrado | SwiftClient') do
      
  obj = create_bin_payload 1
  obj10 = create_bin_payload 10
  obj100 = create_bin_payload 100

  tests("#upload") do

    tests("responds to") do
      [:upload].each do |m|
        test "#{m}" do
          client.respond_to? m
        end
      end
    end

    raises ArgumentError, "ArgumentError when container nil" do
      client.upload nil, 'foo'
    end
    raises ArgumentError, "ArgumentError when object nil" do
      client.upload 'foo', nil
    end
    raises ArgumentError, "when not enough arguments" do
      client.upload
    end

    tests "success" do
      test "upload OK" do
        status = client.upload('cifrado-tests', obj) 
        status == 201
      end

      test "correct path" do
        file = create_bin_payload 1
        client.upload('cifrado-tests', file) 
        dir = client.service.directories.get 'cifrado-tests'
        !(dir.files.get file[1..-1]).nil?
      end
      
      test "custom object path" do
        file = create_bin_payload 1
        client.upload('cifrado-tests', file, :object_path => '/foobar')
        dir = client.service.directories.get 'cifrado-tests'
        !(dir.files.get 'foobar').nil?
      end
    end

    tests "upload block" do
      chunks = []
      client.upload('cifrado-tests', obj) do |chunk|
        chunks << chunk
      end
      test "yields chunks" do
        chunks.size > 0
      end
      test "chunks equal File.size" do
        # FIXME
        # File.size should be equal to the bytes read
        # but StreamUploader is buggy
        File.size(obj) <= chunks.inject(:+)
      end
    end
  end

  clean_test_payloads
  dir = client.service.directories.get('cifrado-tests')
  dir.files.each do |f|
    f.destroy
  end
  dir.destroy

  cleanup 

end
