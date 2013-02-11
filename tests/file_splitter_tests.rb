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

    test 'calculate chunks' do
      s = FileSplitter.new obj100
      s.split.size == 10 and !s.reused_chunks?
    end
    
    test 're-use chunks' do
      s = FileSplitter.new obj100
      s.split
      s.reused_chunks?
    end
    
    test 'discard-chunks' do
      s = FileSplitter.new obj100, 30
      s.split
      !s.reused_chunks?
    end
    

  end

  test '#clean_cache' do
    s = FileSplitter.new obj100
    s.split
    s.clean_cache
    Dir["#{s.cache_dir}/*chunk-*"].size == 0 and Dir["#{s.cache_dir}/*md5"].size == 0
  end

  cleanup
end
