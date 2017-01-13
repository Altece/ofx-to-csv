require 'date'
require 'time'

require 'rubygems'
require 'bundler/setup'
require 'ofx-parser'

# This is necessary to fix a bug which causes a crash when date is nil.
module OfxParser
  class OfxParser
    def self.parse_datetime(date)
      return DateTime.parse date unless date.nil? or date.strip == ""
      return nil
    end
  end
end
