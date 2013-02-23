Shindo.tests('Cifrado | SwiftClient') do
      
  obj = create_bin_payload 1

  tests('set_acl') do
    dir = test_container
    response = client.set_acl '.r:*,.rlistings', test_container.key
    test 'success' do
      [202,201].include? response.status
    end
    test 'ACL present' do
      response = client.service.request :method => 'GET', 
                                        :path => test_container.key
      response.headers['X-Container-Read'] == '.r:*,.rlistings'
    end
    dir.destroy
  end

  tests('#encrypted_upload') do
    test 'success' do
      response = client.encrypted_upload('cifrado-tests', obj) 
      cipher = CryptoEngineAES.new client.api_key
      headers = client.head(test_container_name, clean_object_name(obj))
      fname = headers['X-Object-Meta-Encrypted-Name']
      ([202,201].include? response.status) and obj == cipher.decrypt(fname)
    end
  end

end
