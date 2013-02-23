Shindo.tests('Cifrado | SwiftClient#download') do
    
  cwd = Dir.pwd
  cli_options = {
    :insecure => true,
    :no_progressbar => true
  }

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
        cli.options = cli_options.merge({
          :encrypt  => 'a:rubiojr',
        })
        obj_path = cli.upload test_container_name, obj
        r = client.download test_container_name, 
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
        cli.options = cli_options.merge({
          :encrypt  => 'a:rubiojr',
        })
        obj_path = cli.upload test_container_name, obj
        r = client.download test_container_name, 
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
        cli.options = cli_options
        obj_path = cli.upload test_container_name, obj
        r = client.download test_container_name, 
                            obj_path,
                            :decrypt => true
        downloaded_file = File.join(output, obj)
        r.status == 200 and \
          Digest::MD5.file(downloaded_file) == md5 and \
          File.read(downloaded_file).strip.chomp == 'foobar'
      end
      Dir.chdir cwd

      tests 'container' do
        clean_test_container

        container = test_container
        obj = create_bin_payload 1
        obj2 = create_bin_payload 1
        obj3 = create_bin_payload 1, tmpfile + "/foo/bar/file1"
        output = "/tmp/cifrado-objects-#{SecureRandom.hex}"
        cli = Cifrado::CLI.new
        cli.options = cli_options.merge({
          :segments => 3,
          :encrypt => "s:#{passphrase}"
        })
        [obj, obj2, obj3].each do |o|
          cli.upload container.key, o
        end
        sleep 5
        
        raises ArgumentError, 'download to invalid dir' do
          client.download container.key, 
                          nil, 
                          :output => output,
                          :decrypt => true,
                          :passphrase => passphrase
        end

        tests "contents in #{output}" do
          FileUtils.mkdir output
          returns(Excon::Response,"download contents to #{output}") do
            client.download(container.key, 
                            nil, 
                            :output => output,
                            :decrypt => true,
                            :passphrase => passphrase).class
          end
          [obj, obj2, obj3].each do |o|
            test "includes #{o}" do
              Dir["#{output}/**/*"].include?(File.join(output, obj))
            end
          end
          test "file #{obj3} exist" do
            File.exist?(File.join(output, obj3))
          end
        end

        tests 'file MD5 digest' do
          hashes = []
          hashes << Digest::MD5.file(obj)
          hashes << Digest::MD5.file(obj2)
          hashes << Digest::MD5.file(obj3)
          Dir["#{output}/**/*"].each do |f|
            next if File.directory?(f)
            digest = Digest::MD5.file(f)
            test "includes #{digest}" do
              hashes.include?(digest)
            end
          end
        end
      end

    end

    test "to current dir" do
      obj = create_bin_payload 1
      md5 = Digest::MD5.file obj
      client.upload(test_container_name, obj) 
      cwd = Dir.pwd
      Dir.mkdir '/tmp/cifrado'
      Dir.chdir '/tmp/cifrado'
      r = client.download test_container_name,
                          obj
      file = File.join(Dir.pwd, obj)
      Digest::MD5.file(file) == md5 
    end
    Dir.chdir cwd

    test 'segmented file' do
      obj = create_bin_payload 1
      md5 = Digest::MD5.file obj
      cli = Cifrado::CLI.new
      cli.options = cli_options.merge({
        :segments => 3
      })
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
      cli.options = cli_options.merge({
        :segments => 3,
      })
      cli.upload container.key, obj
      cli.upload container.key, obj2
      sleep 5
      output = "/tmp/cifrado-objects-#{SecureRandom.hex}"
      FileUtils.mkdir output
      client.download container.key, nil, :output => output
      Dir["#{output}/**/*"].size == 3
    end
    
    tests "progress callback" do
      obj = create_bin_payload 1
      chunks = []
      cb = Proc.new do |bytes|
        chunks << bytes 
      end
      client.upload test_container_name, obj
      client.download test_container_name, 
                      obj, 
                      :output => tmpfile,
                      :progress_callback => cb
      test "chunks equal File.size" do
        # FIXME
        # File.size should be equal to the bytes read
        # but StreamUploader is buggy
        File.size(obj) == chunks.inject(:+)
      end
    end
  end

end
