Shindo.tests('Cifrado | CLI#list') do

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
    test 'cifrado-tests-list container exists' do
      dir = client.service.directories.create :key => 'cifrado-tests-list'
      cli = Cifrado::CLI.new
      cli.options = {
        :insecure => true,
        :no_progressbar => true
      }
      !(cli.list.find { |d| d.key == 'cifrado-tests-list' }).nil?
      dir.destroy
    end
  end

end
