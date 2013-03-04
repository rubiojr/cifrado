include Cifrado::Utils

Shindo.tests('Cifrado | CLI#upload') do

  cfg = YAML.load_file(
    File.join(ENV['HOME'], '.config/cifrado/cifradorc')
  ) rescue nil
  cli_options = {
    :insecure => true,
    :no_progressbar => true
  }
  cli_options.merge!(cfg[:cli_options]) if cfg[:cli_options]

  tests '#upload' do
    tests 'segmented uploads' do
      obj = create_bin_payload 1*1024
      cli = Cifrado::CLI.new
      cli.options = {
        :segments => 3
      }.merge cli_options
      segments = cli.upload 'cifrado-tests', obj
      test "#{test_container.key} is a Hash" do
        cli.stat('cifrado-tests', obj).is_a?(Hash) 
      end
      test "uploaded 4 segments" do
        segments.size == 4 
      end
      test "segment matches /segments/..." do
        !segments.last.match(/segments\/\d+.\d{2}\/\d+\/00000003$/).nil?
      end
      test 'uploaded segments not uploaded twice' do
        segments = cli.upload 'cifrado-tests', obj
        segments.size == 0
      end
    end
    tests 'single uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = cli_options
      cli.upload 'cifrado-tests', obj
      test 'upload ok' do
        cli.stat('cifrado-tests', obj).is_a?(Hash)
      end
      test 'do not uploaded twice' do
        segments = cli.upload 'cifrado-tests', obj
        segments.size == 0
      end
    end

    tests 'encrypted uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :encrypt  => 'a:rubiojr'
      }.merge cli_options
      obj_path = (cli.upload 'cifrado-tests', obj).first
      test 'stat' do 
        cli.stat('cifrado-tests', obj_path).is_a?(Hash)
      end
      test 'X-Object-Meta-Encrypted-Name' do
        !cli.stat('cifrado-tests', obj_path)['X-Object-Meta-Encrypted-Name'].nil?
      end
      test 'decrypted name matches' do
        header = cli.stat('cifrado-tests', obj_path)['X-Object-Meta-Encrypted-Name']
        decrypted_name = decrypt_filename header, 
                                          cli.config[:password] + cli.config[:secure_random]
        decrypted_name == obj 
      end

      clean_test_container
      obj1 = create_bin_payload 1, "/tmp/cifrado-upload-dir/foo"
      obj2 = create_bin_payload 1, "/tmp/cifrado-upload-dir/bar/foo"
      obj3 = create_bin_payload 1, "/tmp/cifrado-upload-dir/stuff/bar/foo"
      cli.upload test_container.key, "/tmp/cifrado-upload-dir/"
      sleep 2
      test 'directory upload' do
        test_container.files.size == 3
      end
    end
    
    tests 'encrypted segmented uploads' do
      clean_test_container
      obj = create_bin_payload 1*1024
      cli = Cifrado::CLI.new
      cli.options = {
        :segments => 3,
        :encrypt  => 'a:rubiojr'
      }.merge cli_options
      segments = cli.upload 'cifrado-tests', obj
      test 'stat' do
        cli.stat('cifrado-tests', segments.first).is_a?(Hash) 
      end
      # If the file size after encryption (GPG uses compression by default)
      # is smaller than 4096*3, the number of segments will be less than 3
      # in this case, so the following test will not work.
      test 'segments number' do
        # 1 plus manifest
        segments.size == 4
      end
      test 'segment name matches' do
        !segments.last.match(/segments\/\d+.\d{2}\/\d+\/00000003$/).nil?
      end
      count = 0
      segments.each do |s|
        count += 1
        if count == 1
          test "segment #{s} has encryption header" do
            !cli.stat(test_container.key, s)['X-Object-Meta-Encrypted-Name'].nil?
          end
          test "manifest #{s} name can be decrypted" do
            header = cli.stat(test_container.key, s)['X-Object-Meta-Encrypted-Name']
            decrypted_name = decrypt_filename header, 
                                              cli.config[:password] + cli.config[:secure_random]
            decrypted_name == obj
          end
        else
          test "segment #{s} has encryption header" do
            !cli.stat(test_container_segments_name, s)['X-Object-Meta-Encrypted-Name'].nil?
          end
          test "segment #{s} name can be decrypted" do
            header = cli.stat(test_container_segments_name, s)['X-Object-Meta-Encrypted-Name']
            decrypted_name = decrypt_filename header, 
                                              cli.config[:password] + cli.config[:secure_random]
            (decrypted_name =~ /#{obj}\/segments\//) == 0
          end
        end
      end
    end
    
    tests 'encrypted symmetric segmented uploads' do
      clean_test_container
      obj = create_bin_payload 1*1024
      cli = Cifrado::CLI.new
      cli.options = {
        :segments => 3,
        :encrypt  => 's:foobar'
      }.merge cli_options
      segments = cli.upload 'cifrado-tests', obj
      test "HEAD manifest returns a Hash" do
        cli.stat(test_container.key, segments.first).is_a?(Hash) 
      end
      test "4 segments found" do
        segments.size == 4
      end
      test "segment name matches /segments\/\d+.\d{2}\/\d+\/00000003" do
        !segments.last.match(/segments\/\d+.\d{2}\/\d+\/00000003$/).nil?
      end
      test "#{test_container_segments_name} container found" do
        cli.stat(test_container.key).is_a?(Hash) 
      end
      test "#{test_container_segments_name} container hash 3 segments" do
        cli.list(test_container_segments_name).size == 3
      end
    end
    
    test 'encrypted symmetric uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :encrypt  => 's:foobar',
      }.merge cli_options
      obj_path = (cli.upload 'cifrado-tests', obj).first
      !cli.stat('cifrado-tests', obj_path)['X-Object-Meta-Encrypted-Name'].nil?
    end
  end
  
end
