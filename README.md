# Cifrado

**WARNING** 

The current Cifrado release is experimental. Use at your own risk.

OpenStack Swift CLI with built in (GPG) encryption.

There's an **ongoing** effort to document Cifrado in the Wiki. Additional details such as
documentation to bootstrap your own Swift All-In-One server with Cifrado and the demo
server available are documented there.

See [Cifrado Demo Server](https://github.com/rubiojr/cifrado/wiki/Cifrado-Demo-Server) and [Cifrado SAIO Bootstrap](https://github.com/rubiojr/cifrado/wiki/Cifrado-SAIO-bootstrap).

## Features available in Cifrado 0.1

* Uploading/downloading files and directories to/from OpenStack Swift.
* Regular list/delete/stat commands to manipulate objects and containers.
* Asymmetric/Symmetric transparent encryption/decryption of files
  when uploading/downloading using GnuPG.
* Segmented uploads (splitting the file in multiple segments).
* Resume (unencrypted) segmented uploads. Segments already uploaded
  are not uploaded again. This feature does not work when using
  file encryption at the moment.
* Different progressbar styles. CLI does not have to be boring :).
* Bandwidth limits when uploading/downloading stuff.
* Music streaming (streams mp3/ogg files available in a container)
  and plays them using mplayer/vlc/totem if available.
* Video streaming (streams video files available in a container).
* Bootstrap a Swift All-In-One server in a cloud provider
  (DigitalOcean is the only one supported ATM).
* Ruby 1.8.7, 1.9.X and 2.0 compatibility.

Cifrado has a built-in help command:

```
$ cifrado help

Tasks:
  cifrado cinema CONTAINER VIDEO              # Stream videos from the target container
  cifrado delete CONTAINER [OBJECT]           # Delete specific container or object
  cifrado download [CONTAINER] [OBJECT]       # Download container, objects
  cifrado help [TASK]                         # Describe available tasks or one specifi...
  cifrado jukebox CONTAINER                   # Play music randomly from the target con...
  cifrado list [CONTAINER]                    # List containers and objects
  cifrado post CONTAINER [DESCRIPTION]        # Create a container
  cifrado saio SUBCOMMAND ...ARGS             # Bootstrap a Swift installation
  cifrado set-acl CONTAINER --acl=ACL         # Set an ACL on containers and objects
  cifrado setup                               # Initial Cifrado configuration
  cifrado stat [CONTAINER] [OBJECT]           # Displays information for the account, c...
  cifrado upload CONTAINER FILE1 [FILE2] ...  # Upload files or directories

Options:
  [--username=USERNAME]  
  [--quiet=QUIET]        
  [--password=PASSWORD]  
  [--auth-url=AUTH_URL]  
  [--tenant=TENANT]      
  [--config=CONFIG]      
  [--region=REGION]      
  [--insecure]           # Insecure SSL connections
  [--debug]              
```

## Installation

### Installing the Ubuntu packages (recommended)

Ubuntu packages are available in Cifrado's PPA for Ubuntu
Precise (12.04), Quantal (12.10) and Raring Ringtail (13.04).

To add the PPA and install the packages, open a terminal and type:

```
sudo add-apt-repository ppa:rubiojr/cifrado
sudo apt-get update
sudo apt-get install cifrado mplayer --no-install-recommends
```

You'll also need GnuPG and MPlayer installed if you want to have
music streaming and encryption support enabled in Cifrado
(GnuPG and the agent is pre-installed in a regular Ubuntu 
installation):

    sudo apt-get install mplayer gnupg gnupg-agent

### Installing via rubygems

Needs rubygems and ruby available in your system.

Ubuntu installation:

    sudo apt-get install ruby rubygems

Install the gem:

    sudo gem install cifrado

## Basic usage

### Setting up Cifrado for the first time

If you already have a Swift installation running,
you can use 'cifrado setup' to configure Cifrado for the first time.

The setup process is optional but highly recommended.
If you run setup, you won't be asked for the username,
password, auth_url and other parameters required to run Cifrado.

The setup command will ask you for the OpenStack Swift authentication
parameters:

    $ cifrado setup
    Running cifrado setup...
    Please provide OpenStack/Rackspace credentials.
    
    Cifrado can save this settings in /home/rubiojr/.config/cifrado/cifradorc
    for later use.
    The settings (password included) are saved unencrypted.
    
    Username: user
    Tenant: my_tenant
    Password: 
    Auth URL: https://identity.example.net/v2.0/tokens
    Do you want to save these settings? (y/n)  

There's an alternative way to setup Cifrado and provision a Swift All-In-One
server for testing and/or personal use. Head over to the Wiki for more
details.

### Uploading/Downloading files with Cifrado

#### Uploading files

Uploading a single file, LICENSE.txt, to container 'test':

```
$ cifrado upload test LICENSE.txt

Uploading LICENSE.txt (1.04 KB)
[0.00 Mb/s] Progress: |=====================| 100% [Time: 00:00:02 ]
```

Uploading a directory (recursively) to container 'test':

```
$ cifrado upload test tmp

Uploading tmp/LICENSE.txt (1.04 KB)
 [0.00 Mb/s] Progress: |=====================| 100% [Time: 00:00:02 ]
Uploading tmp/cifrado.gemspec (1.14 KB)
 [0.00 Mb/s] Progress: |=====================| 100% [Time: 00:00:02 ]
```

Limiting upload speed with --bwlimit:

```
$ cifrado upload --bwlimit 0.10 test pkg/cifrado-0.1.gem

Uploading pkg/cifrado-0.1.gem (163.00 KB)
 [0.09 Mb/s] Progress: |=====================| 100% [Time: 00:00:14 ]
```

The bwlimit data rate unit is Mb/s. The same --bwlimit option can
be used when downloading files.

Uploading big files using segments:

```
$ cifrado upload --segments 3 test pkg/cifrado-0.1.gem 
Segmenting file, 3 segments...
Uploading cifrado-0.1.gem segments
Uploading segment 1/3 (56.00 KB)
 [0.00 Mb/s] Segment [1/3]: |================| 100% [Time: 00:00:02 ]
Uploading segment 2/3 (56.00 KB)
 [0.00 Mb/s] Segment [2/3]: |================| 100% [Time: 00:00:02 ]
Uploading segment 3/3 (51.00 KB)
 [0.00 Mb/s] Segment [3/3]: |================| 100% [Time: 00:00:03 ]
```

Note that segments are automatically reassembled by Swift when you
download the object. That is, to download cifrado-0.1.gem from the
test container, download it like any other regular object.

#### Downloading files

#### Encryption support

**Symmetric Encryption**

    cifrado upload --insecure \
                   --encrypt symmetric \
                   my-container audio.mp3

Cifrado will ask you for the password.

You could also specify the password as an argument (not recommended):

    cifrado upload --insecure \
                   --encrypt s:foobar \
                   my-container audio.mp3

**Asymmetric Encryption ('Traditional' GPG encryption)**

    cifrado upload --insecure \
                   --encrypt a:rubiojr@frameos.org \
                   my-container audio.mp3

Or using the key ID:

    cifrado upload --insecure \
                   --encrypt a:F345BE74 \
                   my-container audio.mp3

#### Streaming the music available in a container

Needs mplayer installed:

    sudo apt-get install mplayer

Play the files available in the 'music' container:

```
$ cifrado jukebox music

Cifrado Jukebox
---------------

Ctrl-C once   -> next song
Ctrl-C twice  -> quit

Playing song
  * spotify/Los Lobos/La Bamba.ogg
```

## Advanced usage

There's some extra documentation available in the project's wiki.

Head over to https://github.com/rubiojr/cifrado/wiki to learn about
Cifrado.

## Known issues

* Foo
* Bar
* A lot of them

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
