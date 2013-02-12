* Cifrado::CLI needs heavy refactoring
* Graceful exits (i.e. when hitting Ctrl-C)
* Uploads with progressbar are very inefficient under ruby 1.8 
  (1.9 is slightly better)
* High CPU utilisation when uplading at high speed
* Implement 'swift style' segmented uploads
