Shindo.tests('Cifrado | CryptoServices') do
  
  obj = create_bin_payload 1

  tests('#encrypt') do

    tests('asymmetric') do
      test '1MB file' do
        s = CryptoServices.new :type => :asymmetric,
                               :recipient => 'rubiojr@frameos.org'
        output = s.encrypt obj, "#{obj}.encrypted"
        out = `file #{obj}.encrypted`
        !out.match(/GPG encrypted/).nil? and File.exist?(output)
      end

      test 'with ASCII armor' do
        s = CryptoServices.new :type => :asymmetric,
                               :gpg_extra_args => ['--armor'],
                               :recipient => 'rubiojr@frameos.org'
        out = s.encrypt obj, "#{obj}.encrypted" 
        !File.read(out).match(/BEGIN PGP MESSAGE/m).nil?
      end
      
      test 'with encrypted name' do
        s = CryptoServices.new :type => :asymmetric,
                               :encrypt_name => true,
                               :recipient => 'rubiojr@frameos.org'
        out = s.encrypt obj, "#{obj}" 
        digest = Digest::SHA2.new << obj
        dir = File.dirname(obj)
        (out == File.join(dir, File.join(digest.to_s))) and File.exist?(out)
      end

      raises ArgumentError, 'with wrong gpg binary' do
        s = CryptoServices.new :type => :asymmetric,
                               :recipient => 'rubiojr@frameos.org',
                               :gpg_binary => '/fffoobar'
        s.encrypt obj, "#{obj}.encrypted"
      end

    end

    tests('symmetric') do
      test '1MB file' do
        obj = create_bin_payload 1
        s = CryptoServices.new :type => :symmetric,
                               :passphrase => 'foobar'
        output = s.encrypt obj, "#{obj}.encrypted"
        CryptoServices.encrypted?("#{obj}.encrypted") and File.exist?(output)
      end
      test 'with encrypted name' do
        s = CryptoServices.new :type => :symmetric,
                               :encrypt_name => true,
                               :passphrase => 'foobar'
        out = s.encrypt obj, "#{obj}" 
        digest = Digest::SHA2.new << obj
        dir = File.dirname(obj)
        out == File.join(dir, File.join(digest.to_s))
      end
    end

  end
  
  test 'asymmetric encrypt to stdout' do
    obj = create_bin_payload 1
    s = CryptoServices.new :type => :asymmetric,
                           :recipient => 'rubiojr@frameos.org',
                           :gpg_extra_args => ['--armor']
    out = s.encrypt obj, "#{obj}.encrypted"
    out.match(/BEGIN PGP MESSAGE/m).nil?
  end
  
  test 'symmetric encrypt to stdout' do
    obj = create_bin_payload 1
    s = CryptoServices.new :type => :symmetric,
                           :passphrase => 'foobar',
                           :gpg_extra_args => ['--armor']
    out = s.encrypt obj, "#{obj}.encrypted"
    out.match(/BEGIN PGP MESSAGE/m).nil?
  end

  test '::encrypted?' do
    obj = create_bin_payload 1
    s = CryptoServices.new :type => :asymmetric,
                           :recipient => 'rubiojr@frameos.org'
    s.encrypt obj, "#{obj}.encrypted"
    CryptoServices.encrypted? "#{obj}.encrypted"
  end
  test 'not ::encrypted?' do
    obj = create_bin_payload 1
    !CryptoServices.encrypted? "#{obj}"
  end

  clean_test_payloads
end

Shindo.tests('Cifrado | CryptoEngineAES') do
  tests('#encrypt') do

    test('with aes256') do
      cipher = CryptoEngineAES.new 'foobar'
      out = cipher.encrypt 'blahblah secret'
      out != 'blahblah secret'
    end

  end
  tests('#decrypt') do

    test('with aes256') do
      cipher = CryptoEngineAES.new 'foobar'
      out = cipher.decrypt 'U2FsdGVkX194CTByrfUY/rcz4ccnuXqiinW81bKGOGg='
      out == 'blahblah secret'
    end

  end
end
