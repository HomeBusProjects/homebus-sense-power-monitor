# homebus-sense-power-monitor

This is a simple Homebus publisher which talks to the Sense electricar power monitor and reports to Homebus periodically.

Sense does not have a public API. Please treat this carefully. It could change or be shut down at any moment.

Based on https://github.com/brbeaird/sense-energy-node

This is code is currently a mess and is not ready for public use.

## Configuration

Store the following values in `.env`:

- SENSE_USERNAME=email address
- SENSE_PASSWORD=password
- SENSE_DEVICE_ID=find this in the web interface using developer tools
- DIR=full path to the app subdirectory
- APP_PATH=command to run app (for instance: bundle exec ./homebus-sense-power-monitor.rb --verbose)
