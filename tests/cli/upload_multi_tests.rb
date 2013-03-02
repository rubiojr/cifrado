include Cifrado::Utils

Shindo.tests('Cifrado | CLI#upload') do

  cfg = YAML.load_file(
    File.join(ENV['HOME'], '.config/cifrado/cifradorc')
  ) rescue nil
  cli_options = {
    :insecure => true,
    :no_progressbar => true
  }
  cli_options.merge!(cfg[:cli_options]) if cfg
  cli = Cifrado::CLI.new
  cli.options = cli_options

  tests '#upload' do
    tests 'upload 2 files' do
      clean_test_container
      obj = create_bin_payload 1
      obj2 = create_bin_payload 2
      uploaded = cli.upload test_container_name, obj, obj2

      test "2 files uploaded" do
        uploaded.size == 2
      end
      test "MD5 for #{obj} matches" do
        cli.stat(test_container_name, obj)['Etag'] == Digest::MD5.file(obj).to_s
      end
      test "MD5 for #{obj2} matches" do
        cli.stat(test_container_name, obj2)['Etag'] == Digest::MD5.file(obj2).to_s
      end

    end

    tests 'upload 1 file and one directory' do
      clean_test_container
      obj = create_bin_payload 1
      # Dir with 3 files
      tmpdir = populate_tmpdir
      uploaded = cli.upload test_container_name, obj, tmpdir
      test '4 files uploaded' do
        uploaded.size == 4
      end
    end
    
    tests 'encrypt and segment 2 files and one directory' do
      clean_test_container
      obj = create_bin_payload 100
      tmpdir = populate_tmpdir
      cli.options = {
        :segments => 3,
        :encrypt  => 's:foobar'
      }.merge cli_options
      # Dir with 3 files
      uploaded = cli.upload test_container_name, obj, tmpdir
      test '12 files + 4 segments uploaded' do
        # 4 files * 3 segments + 4 manifests
        uploaded.size == 16
      end

      cli.list(test_container_name).each do |o|
        test 'uploads have encryption header' do
          !cli.stat(test_container_name, o)['X-Object-Meta-Encrypted-Name'].nil?
        end
      end

      tests 'uploads can be downloaded and decrypted' do
        tmpdir_out = create_tmpdir
        cli.options = {
          :decrypt => true,
          :passphrase => 'foobar',
          :output => tmpdir_out
        }.merge cli_options
        downloads = cli.download test_container_name
        test 'downloaded 4 files' do
          downloads.size == 4
        end
        test '4 files found' do
          ( Dir["#{tmpdir_out}/**/*"].reject { |f| File.directory?(f) } ).size == 4
        end

        uploaded = ( Dir["#{tmpdir_out}/**/*"].reject { |f| File.directory?(f) } )
        uploaded.map! { |f| File.basename(f) }
        ((Dir["#{tmpdir}/*"] << obj).map { |f| File.basename(f) }).each do |f|
          test "filename #{f} was decrypted" do
            uploaded.include? f
          end
        end
      end
    end

  end

end
