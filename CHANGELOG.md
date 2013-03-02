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
