# Cifrado 0.1.3 - Tue 05 Mar 2013

* Fix regresion in the last release that may break regular OpenStack accounts
* Added version command

# Cifrado 0.1.2 - Mon 04 Mar 2013

* Added Rackspace Cloud Files support
  To use Rackspace Cloud Files, run 'setup' and provide the following
  details when asked:
  
  username: <your Rackspace username>
  password: <your Rackspace password> # NOT THE API KEY!
  
  For US accounts, the auth URL is:
  
  https://identity.api.rackspacecloud.com/v2.0/tokens
  
  For UK accounts:
  
  https://lon.identity.api.rackspacecloud.com/v2.0/tokens


# Cifrado 0.1.1 - Sun 03 Mar 2013

* saio command improvements
  * flavors: list flavors available
  * images:  list images available
  * regions: list regions available
* Also added --disk-size bootstrap option to tweak the size
  of the disk image created for Swift storage while bootstraping.
* Bootstrap now prints copy&paste ready configuration for cifrado.


```
SLOC  Directory SLOC-by-Language (Sorted)
2057    lib             ruby=1742,sh=315
983     tests           ruby=983


Totals grouped by language (dominant language first):
ruby:          2725 (89.64%)
sh:             315 (10.36%)




Total Physical Source Lines of Code (SLOC)                = 3,040
Development Effort Estimate, Person-Years (Person-Months) = 0.64 (7.71)
 (Basic COCOMO model, Person-Months = 2.4 * (KSLOC**1.05))
Schedule Estimate, Years (Months)                         = 0.45 (5.43)
 (Basic COCOMO model, Months = 2.5 * (person-months**0.38))
Estimated Average Number of Developers (Effort/Schedule)  = 1.42
Total Estimated Cost to Develop                           = $ 86,828
 (average salary = $56,286/year, overhead = 2.40).
SLOCCount, Copyright (C) 2001-2004 David A. Wheeler
SLOCCount is Open Source Software/Free Software, licensed under the GNU GPL.
```

# Cifrado 0.1 - Sun 03 Mar 2013

* Uploading/downloading files and directories to OpenStack Swift.
* Asymmetric/Symmetric transparent encryption/decryption of files
  when uploading/downloading using GnuPG.
* Segmented uploads (splitting the file in multiple segments).
* Resume (unencrypted) segmented uploads. Segments already uploaded
  are not uploaded again. This feature does not work when using
  file encryption at the moment.
* Different progressbar styles. CLI does not have to be boring :).
* Bandwidth limits when uploading/downloading stuff.
* Music streaming (streams mp3/ogg files available in a container).
  and plays them using mplayer if available).
* Regular list/delete/stat commands.
* Video streaming (streams video files available in a container).
* Bootstrap a Swift All-In-One server in a cloud provider
  (DigitalOcean is the only one supported ATM).
* Ruby 1.8.7, 1.9.X and 2.0 compatibility.


```
SLOC  Directory SLOC-by-Language (Sorted)
1978    lib             ruby=1663,sh=315
918     tests           ruby=918
5       bin             ruby=5


Totals grouped by language (dominant language first):
ruby:          2586 (89.14%)
sh:             315 (10.86%)




Total Physical Source Lines of Code (SLOC)                = 2,901
Development Effort Estimate, Person-Years (Person-Months) = 0.61 (7.34)
 (Basic COCOMO model, Person-Months = 2.4 * (KSLOC**1.05))
Schedule Estimate, Years (Months)                         = 0.44 (5.33)
 (Basic COCOMO model, Months = 2.5 * (person-months**0.38))
Estimated Average Number of Developers (Effort/Schedule)  = 1.38
Total Estimated Cost to Develop                           = $ 82,664
 (average salary = $56,286/year, overhead = 2.40).
SLOCCount, Copyright (C) 2001-2004 David A. Wheeler
```
