Shindo.tests('Cifrado | CryptoServices') do
  
  obj = create_bin_payload 1

  tests('#encrypt') do

    test '1MB file' do
      s = CryptoServices.new
      s.encrypt obj, "#{obj}.encrypted", :recipient => 'rubiojr@frameos.org'
      out = `file #{obj}.encrypted`
      !out.match(/GPG encrypted/).nil?
    end

  end

  test '::encrypted?' do
    s = CryptoServices.new
    s.encrypt obj, "#{obj}.encrypted", :recipient => 'rubiojr@frameos.org'
    CryptoServices.encrypted? "#{obj}.encrypted"
  end

  clean_test_payloads
end
