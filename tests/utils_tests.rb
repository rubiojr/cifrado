include Cifrado::Utils

Shindo.tests('Cifrado | Utils') do

  tests 'clean_object_name' do
    test './foo/bar/stuff' do
      clean_object_name('./foo/bar/stuff') == 'foo/bar/stuff'
    end
    test '//foo/bar/stuff' do
      clean_object_name('//foo/bar/stuff') == 'foo/bar/stuff'
    end
    test '/foo/bar/stuff' do
      clean_object_name('/foo/bar/stuff') == 'foo/bar/stuff'
    end
    test 'foo/bar/stuff' do
      clean_object_name('foo/bar/stuff') == 'foo/bar/stuff'
    end
  end

  test 'encrypt_filename' do
    cs = CryptoEngineAES.new passphrase
    filename = "/tmp/cifrado-payload-foobaro8u2ojf98"
    n = cs.encrypt filename
    cs.decrypt(n) == filename and n.lines.count == 1
  end

  test 'decrypt_filename' do
    cs = CryptoEngineAES.new passphrase
    fname = 'U2FsdGVkX19Wm6CdV6LF7j7wATQjH02-jeOJTy-Rt_Qs4WCDRblLWvHkvadbuZV9OKn0Rc5_X4BOwspPSV6ZBA=='
    cs.decrypt(fname) == "/tmp/cifrado-payload-foobaro8u2ojf98"
  end
  
end
