### Terminal Twitter ###
#
#  Gives you the ability to access a twitter account
#  via the terminal command line
#

APP_ROOT = File.dirname(__FILE__)
$:.unshift(File.join(APP_ROOT, 'lib'))

require 'guide'

guide = Guide.new('twitters.txt')
guide.launch!