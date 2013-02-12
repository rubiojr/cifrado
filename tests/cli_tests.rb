Shindo.tests('Cifrado | CLI') do

  tests '#upload' do
    test 'segmented uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :no_progressbar => true
      }
      segments = cli.upload 'cifrado-tests', obj
      cli.stat('cifrado-tests', obj).is_a?(Hash) and \
        segments.size == 4 and \
        (!segments.last.match(/-chunk-3$/).nil?)
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

    test 'encrypted uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :encrypt  => 'a:rubiojr',
        :no_progressbar => true
      }
      obj_path = cli.upload 'cifrado-tests', obj
      cli.stat('cifrado-tests', obj_path).is_a?(Hash)
    end
    
    test 'encrypted segmented uploads' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :encrypt  => 'a:rubiojr',
        :no_progressbar => true
      }
      segments = cli.upload 'cifrado-tests', obj
      cli.stat('cifrado-tests', segments.first).is_a?(Hash) and \
        segments.size == 4 and \
        (!segments.last.match(/-chunk-3$/).nil?)
    end
    
    test 'encrypted symmetric segmented uploads' do
      obj = create_bin_payload 1
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
        (!segments.last.match(/-chunk-3$/).nil?)
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
  
  cleanup

  tests '#list' do
    test 'container has 1 element' do
      obj = create_bin_payload 1
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :no_progressbar => true
      }
      cli.upload 'cifrado-tests', obj
      (cli.list 'cifrado-tests').size == 1
    end
  end

end
