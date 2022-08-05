# coding: utf-8

require 'homebus'

require 'dotenv'

require 'net/http'
require 'json'

class SensePowerHomebusApp < Homebus::App
  DDC = 'org.homebus.experimental.power-flow'

  def initialize(options)
    @options = options
    super
  end

  def update_interval
    15*60
  end

  def setup!
    Dotenv.load('.env')
    @device_id = @options[:device_id] || ENV['SENSE_DEVICE_ID']

    @device = Homebus::Device.new name: "Sense Power Monitor publisher",
                                  manufacturer: 'Homebus',
                                  model: '',
                                  serial_number: @device_id

  end

  def work!
    line = gets

    exit unless line

    data = JSON.parse(line, symbolize_names: true)

    if options[:verbose]
      pp data
    end

    payload = {
      hz: data[:average_hz],
      min_voltage: data[:low_voltage],
      max_voltage: data[:high_voltage],
      watts: data[:watts],
      interval: data[:seconds]
    }

    @device.publish! DDC, payload

    if options[:verbose]
      pp DDC, payload
    end
  end

  def name
    'Homebus Sense Power Monitor publisher'
  end

  def publishes
    [ DDC ]
  end

  def devices
    [ @device ]
  end
end
