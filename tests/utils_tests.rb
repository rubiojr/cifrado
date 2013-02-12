include Cifrado::Utils
Shindo.tests('Cifrado | Utils') do
  
  tests('#encrypt_filename') do

    tests('asymmetric') do
      out = encrypt_filename 'foobar', 
                             :encrypt => 'a:rubiojr@frameos.org'
      out =! 'foobar'
    end

  end

end
