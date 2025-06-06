# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register 'application/octet-stream', :job
Mime::Type.register 'application/vnd.google-earth.kml+xml', :kml
Mime::Type.register('application/geo+json', :geojson)
