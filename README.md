# Cifrado

OpenStack Swift CLI with built in (gpg) encryption.

## Installation

Install it yourself as:

    $ gem install cifrado

Nees the GPG binary installed to use encryption.

## Usage

It has built-in help:

    cifrado help

or 

    cifrado help <command>

### Encrypted, symmetric uploads

    cifrado upload --insecure \
                   --encrypt symmetric \
                   my-container audio.mp3

Cifrado will ask you for the password.

You could also specify the password as an argument (not recommended):

    cifrado upload --insecure \
                   --encrypt s:foobar \
                   my-container audio.mp3

### Encrypted, asymmetric uploads

    cifrado upload --insecure \
                   --encrypt a:rubiojr@frameos.org \
                   my-container audio.mp3

Or using the key ID:

    cifrado upload --insecure \
                   --encrypt a:F345BE74 \
                   my-container audio.mp3

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
