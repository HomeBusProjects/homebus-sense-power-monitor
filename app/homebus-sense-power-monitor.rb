#!/usr/bin/env ruby

require './options'
require './app'

sense_app_options = SensePowerHomebusAppOptions.new

sense = SensePowerHomebusApp.new sense_app_options.options
sense.run!
