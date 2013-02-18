Shindo.tests('Cifrado | FileSplitter') do
  
  obj = create_bin_payload 1
  obj10 = create_bin_payload 10*1024
  obj100 = create_bin_payload 100*1024

  tests('#split') do

    tests('10MB file') do
      s = FileSplitter.new obj10, 10
      count = 1
      chunks = s.split
      chunks.each do |chunk|
        test "generates chunk ##{count}" do
          File.exist?(chunk)
        end
        test "the chunk #{chunk} has the correct size" do
          # Each chunk is 1K
          File.size(chunk) == 1024*1024
        end
        count += 1
      end
      
      test 'md5 matches' do
        t = tmpfile
        chunks.each do |c|
          `/bin/cat #{c} >> #{t}`
        end
        Digest::MD5.file(t) == Digest::MD5.file(obj10)
      end
    end

    test '8KB file' do
      s = FileSplitter.new create_bin_payload(8), 2
      s.split.size == 2
    end
    
    test '10KB file' do
      s = FileSplitter.new create_bin_payload(10), 4
      s.split.size == 3
    end

    test 'split 1K in 2 returns 1 chunk' do
      s = FileSplitter.new obj, 2
      s.split.size == 1
    end

    test 'calculate chunks' do
      s = FileSplitter.new obj100
      s.split.size == 10 
    end
    
    test 'discard-chunks' do
      s = FileSplitter.new obj100, 30
      chunks = s.split
      chunks.size == 30
    end
    
  end

end
