Shindo.tests('Cifrado | FileSplitter') do
  
  obj = create_bin_payload 1
  obj10 = create_bin_payload 10
  obj100 = create_bin_payload 100

  tests('#split') do

    tests('10MB file') do
      s = FileSplitter.new obj10, 10
      count = 1
      s.split.each do |chunk|
        test "generates chunk ##{count}" do
          File.exist?(chunk)
        end
        test 'the chunk has the correct size' do
          # Each chunk is 1MB
          File.size(chunk) == 1024**2
        end
        count += 1
      end
    end

    test 'split 1MB in 2' do
      s = FileSplitter.new obj, 2
      s.split.size == 2
    end

    test 'accepts processor' do
      s = FileSplitter.new obj10, 10
      processed = []
      s.split :processor => Proc.new { |chunk| processed << chunk }
      processed.size == 10
    end

    s = FileSplitter.new obj10, 10
    cs = CryptoServices.new
    s.split(:processor => Proc.new do |chunk| 
      cs.encrypt chunk, "#{chunk}.encrypted", :recipient => 'rubiojr@frameos.org'
      FileUtils.mv "#{chunk}.encrypted", chunk
    end).each do |echunk|
      test 'encrypts chunk using CryptoServices' do
        CryptoServices.encrypted? echunk
      end
    end

    test 'calculate chunks' do
      s = FileSplitter.new obj100
      s.split.size == 10
    end
  end

  cleanup
end
