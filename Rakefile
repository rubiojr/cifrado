require "bundler/gem_tasks"
require 'fileutils'
require './lib/cifrado/version.rb'

PROJECT = 'cifrado'
PROJECT_VERSION = Cifrado::VERSION

task :deb, :destdir do |t, args|
  destdir = (args[:destdir] || '/tmp')
  FileUtils.mkdir_p(destdir) unless File.directory?(destdir)
  pwd = Dir.pwd
  Dir.chdir '../'
  system "tar --exclude #{PROJECT}/.git --exclude #{PROJECT}/exclude --exclude " + \
         "#{PROJECT}/debian " + \
         "--exclude #{PROJECT}/pkg " + \
         "-czf #{destdir}/#{PROJECT}_#{PROJECT_VERSION}.orig.tar.gz " + \
         "#{PROJECT}"
  Dir.chdir "#{destdir}"
  system "tar xzf #{PROJECT}_#{PROJECT_VERSION}.orig.tar.gz"
  Dir.chdir pwd
  system "cp -r debian #{destdir}/#{PROJECT}/"
end
