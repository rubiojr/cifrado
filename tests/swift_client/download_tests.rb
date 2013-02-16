Shindo.tests('Cifrado | SwiftClient#download') do

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
    test 'segmented file' do
      obj = create_bin_payload 1
      md5 = Digest::MD5.file obj
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :segments => 3,
        :no_progressbar => true
      }
      segments = cli.upload 'cifrado-tests', obj
      sleep 5
      output = "/tmp/cifrado-tests-#{SecureRandom.hex}"
      r = client.download 'cifrado-tests', 
                          obj,
                          :output => output
      r.status == 200 and Digest::MD5.file(output) == md5
    end
  end

  # Cleanup
  Dir["/tmp/cifrado-tests*"].each { |f| File.delete f }
  cleanup

end
