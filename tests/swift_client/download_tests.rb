Shindo.tests('Cifrado | SwiftClient#download') do
    
  cwd = Dir.pwd

  tests "#download" do
    test "object" do
      obj = create_bin_payload 1
      md5 = Digest::MD5.file obj
      client.upload('cifrado-tests', obj) 
      output = "/tmp/cifrado-tests-#{SecureRandom.hex}"
      r = client.download 'cifrado-tests', 
                          obj,
                          :output => output
      r.status == 200 and Digest::MD5.file(output) == md5
    end
    
    tests "download and decrypt" do
      test 'with output option' do
        obj = create_text_payload 'foobar'
        md5 = Digest::MD5.file obj
        output = "/tmp/cifrado-tests-#{SecureRandom.hex}"
        cli = Cifrado::CLI.new
        cli.options = {
          :insecure => true,
          :encrypt  => 'a:rubiojr',
          :no_progressbar => true
        }
        obj_path = cli.upload test_container.key, obj
        r = client.download test_container.key, 
                            obj_path,
                            :output => output,
                            :decrypt => true
        r.status == 200 and \
          Digest::MD5.file(output) == md5 and \
          File.read(output).strip.chomp == 'foobar'
      end

      test 'witout output' do
        obj = create_text_payload 'foobar'
        md5 = Digest::MD5.file obj
        output = "/tmp/cifrado-tests-#{SecureRandom.hex}"
        Dir.mkdir output
        Dir.chdir output
        cli = Cifrado::CLI.new
        cli.options = {
          :insecure => true,
          :encrypt  => 'a:rubiojr',
          :no_progressbar => true
        }
        obj_path = cli.upload test_container.key, obj
        r = client.download test_container.key, 
                            obj_path,
                            :decrypt => true
        downloaded_file = File.join(output, obj)
        r.status == 200 and \
          Digest::MD5.file(downloaded_file) == md5 and \
          File.read(downloaded_file).strip.chomp == 'foobar'
      end
      Dir.chdir cwd

      test 'not really encrypted' do
        obj = create_text_payload 'foobar'
        md5 = Digest::MD5.file obj
        output = "/tmp/cifrado-tests-#{SecureRandom.hex}"
        Dir.mkdir output
        Dir.chdir output
        cli = Cifrado::CLI.new
        cli.options = {
          :insecure => true,
          :no_progressbar => true
        }
        obj_path = cli.upload test_container.key, obj
        r = client.download test_container.key, 
                            obj_path,
                            :decrypt => true
        downloaded_file = File.join(output, obj)
        r.status == 200 and \
          Digest::MD5.file(downloaded_file) == md5 and \
          File.read(downloaded_file).strip.chomp == 'foobar'
      end
      Dir.chdir cwd

    end

    test "to current dir" do
      obj = create_bin_payload 1
      md5 = Digest::MD5.file obj
      client.upload(test_container.key, obj) 
      cwd = Dir.pwd
      Dir.mkdir '/tmp/cifrado'
      Dir.chdir '/tmp/cifrado'
      r = client.download test_container.key,
                          obj
      file = File.join(Dir.pwd, obj)
      Digest::MD5.file(file) == md5 
    end
    Dir.chdir cwd

    test 'segmented file' do
      obj = create_bin_payload 1
      md5 = Digest::MD5.file obj
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :no_progressbar => true
      }
      segments = cli.upload 'cifrado-tests', obj
      sleep 5
      output = "/tmp/cifrado-tests-#{SecureRandom.hex}"
      r = client.download 'cifrado-tests', 
                          obj,
                          :output => output
      r.status == 200 and Digest::MD5.file(output) == md5
    end

    cleanup

    test 'container' do
      container = test_container
      obj = create_bin_payload 1
      obj2 = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :no_progressbar => true
      }
      cli.upload container.key, obj
      cli.upload container.key, obj2
      sleep 5
      output = "/tmp/cifrado-objects-#{SecureRandom.hex}"
      FileUtils.mkdir output
      client.download container.key, nil, :output => output
      Dir["#{output}/**/*"].size == 3
    end
  end

  cleanup
end
