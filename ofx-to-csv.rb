#!/usr/bin/env ruby

require 'csv'
require 'date'
require 'fileutils'
require 'time'

require 'rubygems'
require 'bundler/setup'

require 'active_support/inflector'
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

EXTENSION = 'ofxcsv'

input = ARGV.shift
output = ARGV.shift
unless input and File.exist?(input)
  puts "Usage: #{File.basename(__FILE__)} /path/to/statement.ofx [/path/to/output/directory]"
  exit 1
end

unless output
  output = 'Finances'
end
unless output.split('.').last == EXTENSION
  output = "#{output}.#{EXTENSION}"
end

def mkdir_p(path)
  parts = path.split('/')
  growing_path = []
  growing_path_prefix = if path.start_with?('/') then '/' else '' end
  parts.each do |part|
    growing_path << part
    full_path = "#{growing_path_prefix}#{growing_path.join('/')}"
    Dir.mkdir(full_path) unless Dir.exist?(full_path)
  end
  path
end

mkdir_p output

def to_safe_s(obj)
  return "" if obj.nil?
  obj = obj.to_time if obj.class == DateTime or obj.class == Date
  obj = obj.utc if obj.class == Time
  obj = obj.to_s unless obj.class == String
  obj
end

def to_title_s(string)
  return "" if string.nil?
  ActiveSupport::Inflector.titleize(string) unless string.nil?
end

ofx = OfxParser::OfxParser.parse(File.open(input, 'r'))

destination = mkdir_p "#{output}/#{ofx.sign_on.institute.name}"

def write_transactions_into_path(transactions, path)
  File.open("#{path}/Statement.csv", 'w') do |file|
    file.puts ['Type',
               'Type Description',
               'Date',
               'Amount',
               'Amount in Minor Units',
               'FIT ID',
               'Payee',
               'Memo',
               'SIC',
               'SIC Description',
               'Check Number'].map(&method(:to_safe_s)).to_csv
    transactions.each do |transaction|
      file.puts [transaction.type,
                 to_title_s(transaction.type_desc),
                 transaction.date,
                 transaction.amount,
                 transaction.amount_in_pennies,
                 transaction.fit_id,
                 to_title_s(transaction.payee),
                 to_title_s(transaction.memo),
                 transaction.sic,
                 transaction.sic_desc,
                 transaction.check_number].map(&method(:to_safe_s)).to_csv
    end
  end
end

=begin
File.open("#{destination}/SignOn.status.csv", 'w') do |file|
  file.puts ['Code',
             'Code Description',
             'Severity',
             'Message'].map(&method(:to_safe_s)).to_csv
  file.puts [ofx.sign_on.status.code,
             to_title_s(ofx.sign_on.status.code_desc),
             to_title_s(ofx.sign_on.status.severity),
             ofx.sign_on.status.message].map(&method(:to_safe_s)).to_csv
end

File.open("#{destination}/SignOn.csv", 'w') do |file|
  file.puts ['Date',
             'Language',
             'Institute Name',
             'Institute ID'].map(&method(:to_safe_s)).to_csv
  file.puts [ofx.sign_on.date,
             ofx.sign_on.language,
             ofx.sign_on.institute.name,
             ofx.sign_on.institute.id].map(&method(:to_safe_s)).to_csv
end
=end

ofx.bank_accounts.each do |account|
  path = mkdir_p "#{destination}/BankAccount#{account.number}/#{account.statement.end_date.to_time.utc}"

  # read in the account info
  File.open("#{path}/Info.csv", 'w') do |file|
    file.puts ['Account Number',
               'Transaction UID',
               'Routing Number',
               'Balance',
               'Balance in Minor Units',
               'Blance Date',
               'Currency',
               'Start Date',
               'End Date',
               'Amount of Transactions'].map(&method(:to_safe_s)).to_csv
    file.puts [account.number,
               account.transaction_uid,
               account.routing_number,
               account.balance.to_s,
               account.balance_in_pennies,
               account.balance_date,
               account.statement.currency,
               account.statement.start_date,
               account.statement.end_date,
               account.statement.transactions.size].map(&method(:to_safe_s)).to_csv
  end

  write_transactions_into_path(account.statement.transactions, path)
end

ofx.signup_account_info.each do |info|
  path = mkdir_p "#{destination}/BankAccount#{info.number}"

  File.open("#{path}/Account.csv", 'w') do |file|
    file.puts ['Description', 'Account Number', 'Bank ID', 'Type'].map(&method(:to_safe_s)).to_csv
    file.puts [to_title_s(info.desc), info.number, info.bank_id, info.type].map(&method(:to_safe_s)).to_csv
  end
end

ofx.credit_accounts.each do |account|
  path = mkdir_p "#{destination}/CreditCard#{account.number}/#{account.statement.end_date.to_time.utc}"

  # read in the account info
  File.open("#{path}/Info.csv", 'w') do |file|
    file.puts ['Account Number',
               'Transaction UID',
               'Routing Number',
               'Balance',
               'Balance in Minor Units',
               'Blance Date',
               'Remaining Credit',
               'Remaining Credit in Minor Units',
               'Remaining Credit Date',
               'Currency',
               'Start Date',
               'End Date',
               'Amount of Transactions'].map(&method(:to_safe_s)).to_csv
    file.puts [account.number,
               account.transaction_uid,
               account.routing_number,
               account.balance.to_s,
               account.balance_in_pennies,
               account.balance_date.to_time,
               account.remaining_credit.to_s,
               account.remaining_credit_in_pennies,
               account.remaining_credit_date,
               account.statement.currency,
               account.statement.start_date,
               account.statement.end_date,
               account.statement.transactions.size].map(&method(:to_safe_s)).to_csv
  end

  write_transactions_into_path(account.statement.transactions, path)
end
