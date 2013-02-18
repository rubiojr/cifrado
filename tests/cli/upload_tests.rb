include Cifrado::Utils

Shindo.tests('Cifrado | CLI#upload') do

  cli_options = {
    :insecure => true,
    :no_progressbar => true
  }

  tests '#upload' do
    test 'segmented uploads' do
      obj = create_bin_payload 1*1024
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :no_progressbar => true
      }
      segments = cli.upload 'cifrado-tests', obj
      cli.stat('cifrado-tests', obj).is_a?(Hash) and \
        segments.size == 4 and \
        (!segments.last.match(/segments\/\d+.\d{2}\/\d+\/00000003$/).nil?)
    end
    test 'single uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :no_progressbar => true
      }
      cli.upload 'cifrado-tests', obj
      cli.stat('cifrado-tests', obj).is_a?(Hash)
    end

    tests 'encrypted uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :encrypt  => 'a:rubiojr',
        :no_progressbar => true
      }
      obj_path = cli.upload 'cifrado-tests', obj
      test 'stat' do 
        cli.stat('cifrado-tests', obj_path).is_a?(Hash)
      end
      test 'X-Object-Meta-Encrypted-Name' do
        !cli.stat('cifrado-tests', obj_path)['X-Object-Meta-Encrypted-Name'].nil?
      end
      test 'decrypted name matches' do
        header = cli.stat('cifrado-tests', obj_path)['X-Object-Meta-Encrypted-Name']
        decrypted_name = decrypt_filename header, cli.config[:password]
        decrypted_name == obj 
      end
    end
    
    tests 'encrypted segmented uploads' do
      obj = create_bin_payload 1*1024
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :encrypt  => 'a:rubiojr',
        :no_progressbar => true
      }
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
        test "segment #{s} has encryption header" do
          !cli.stat('cifrado-tests', s)['X-Object-Meta-Encrypted-Name'].nil?
        end
        if count == 1
          test "segment #{s} name can be decrypted" do
            header = cli.stat('cifrado-tests', s)['X-Object-Meta-Encrypted-Name']
            decrypted_name = decrypt_filename header, cli.config[:password]
            decrypted_name == obj
          end
        else
          test "segment #{s} name can be decrypted" do
            header = cli.stat('cifrado-tests', s)['X-Object-Meta-Encrypted-Name']
            decrypted_name = decrypt_filename header, cli.config[:password]
            (decrypted_name =~ /#{obj}\/segments\//) == 0
          end
        end
      end
    end
    
    test 'encrypted symmetric segmented uploads' do
      obj = create_bin_payload 1*1024
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :encrypt  => 's:foobar',
        :no_progressbar => true
      }
      segments = cli.upload 'cifrado-tests', obj
      cli.stat('cifrado-tests', segments.first).is_a?(Hash) and \
        segments.size == 4 and \
        (!segments.last.match(/segments\/\d+.\d{2}\/\d+\/00000003$/).nil?)
    end
    
    test 'encrypted symmetric uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :encrypt  => 's:foobar',
        :no_progressbar => true
      }
      obj_path = cli.upload 'cifrado-tests', obj
      cli.stat('cifrado-tests', obj_path).is_a?(Hash)
    end
  end
  
end
