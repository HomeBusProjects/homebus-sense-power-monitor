require 'homebus/options'

class SensePowerHomebusAppOptions < Homebus::Options
  def app_options(op)
    zipcode_help = 'the zip code of the reporting area'

    op.separator 'AQI options:'
    op.on('-z', '--zip-code ZIPCODE', zipcode_help) { |value| options[:zipcode] = value }
  end

  def banner
    'HomeBus Air Quality Index publisher'
  end

  def version
    '0.0.1'
  end

  def name
    'homebus-aqi'
  end
end
