#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'json'
require 'dotenv/load'
require 'cgi'

require 'faye/websocket'
require 'eventmachine'

require 'open3'
require 'date'


def _authenticate
  email = ENV['SENSE_USERNAME']
  password = ENV['SENSE_PASSWORD']

  url = 'https://api.sense.com/apiservice/api/v1/authenticate'
  body = "email=#{CGI.escape(email)}&password=#{CGI.escape(password)}"

  uri = URI(url)
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/x-www-form-urlencoded'

  request.body = body

  response = https.request(request)

  results = JSON.parse(response.body, symbolize_names: true)
  pp results

  token = results[:access_token]
  device_id = results[:monitors][0][:id]

  return token, device_id
end

def _open_ws(token, device_id)
  url = "wss://clientrt.sense.com/monitors/#{device_id}/realtimefeed?access_token=#{token}"
  puts "winsocket URL #{url}"
  return Faye::WebSocket::Client.new(url)
end

app_path = ENV['APP_PATH'].split
Dir.chdir(ENV['DIR'])

EM.run {
  token, device_id = _authenticate

  samples_start_time = 0
  total_samples = 0
  hz_total = 0
  low_voltage = 10000
  high_voltage = -10000
  watts_total = 0

  ws = _open_ws(token, device_id)

  ws.on :open do |event|
    p [:open]
    ws.send('Hello, world!')
  end

  ws.on :message do |event|
    data = JSON.parse(event.data, symbolize_names: true)
    payload = data[:payload]

    unless payload[:hz]
      next
    end

    puts DateTime.now
    puts "hz #{payload[:hz]}"
    puts "low voltage #{payload[:voltage][0]}"
    puts "high voltage #{payload[:voltage][1]}"
    puts "watts #{payload[:d_w]}"
    puts
    puts

    if payload[:epoch] - 60 > samples_start_time
      if samples_start_time != 0
        update= {
          samples: total_samples,
          watts: watts_total,
          average_hz: hz_total / total_samples,
          low_voltage: low_voltage,
          high_voltage: high_voltage,
          seconds: payload[:epoch] - samples_start_time
        }

        hstdin, hstdout, hstderr, wait_thr = Open3.popen3(*app_path)

        hstdin.puts(JSON.generate(update))
        hstdin.close

        exit_code = wait_thr.value

        puts 'homebus out'
        puts hstdout.gets(nil), hstderr.gets(nil)
        puts exit_code
      end

      samples_start_time = payload[:epoch]
      hz_total = 0
      low_voltage = 10000
      high_voltage = -10000
      watts_total = 0
      total_samples = 0
    end

    hz_total += payload[:hz]
    low_voltage = [ low_voltage, payload[:voltage][0] ].min
    high_voltage = [ high_voltage, payload[:voltage][1] ].max
    watts_total += payload[:d_w]
    total_samples += 1
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil

#    _authenticate
    #    _open_ws(token, device_id)
    exit
  end
}
