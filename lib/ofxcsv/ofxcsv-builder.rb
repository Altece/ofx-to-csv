require 'csv'

require_relative 'files'
require_relative 'extensions'

require 'rubygems'
require 'bundler/setup'
require_relative 'ofx-parser-fixes'
require 'active_support/inflector'

module OfxCsv

  class Builder
    attr_reader :destination_dir

    def self.extension
      'ofxcsv'
    end

    def initialize(destination_path)
      @destination_dir = Files::Dir.new "#{destination_path}"
    end

    def parse(file_path)
      file = File.open(file_path, 'r') do |file|
        ofx = OfxParser::OfxParser.parse file
        institute_dir = destination_dir.sub_dir ofx.sign_on.institute.name
        collect_bank_accounts(ofx.bank_accounts, institute_dir)
        collect_credit_accounts(ofx.credit_accounts, institute_dir)
        collect_account_info(ofx.signup_account_info, institute_dir)
      end
      destination_dir.to_s
    end

    using Extensions

    private

    def collect_transactions(transactions, directory)
      directory.open('statement.csv', 'w') do |file|
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
                   'Check Number'].to_csv
        transactions.each do |transaction|
          file.puts [transaction.type,
                     transaction.type_desc.to_title,
                     transaction.date,
                     transaction.amount,
                     transaction.amount_in_pennies,
                     transaction.fit_id,
                     transaction.payee.to_title,
                     transaction.memo.to_title,
                     transaction.sic,
                     transaction.sic_desc,
                     transaction.check_number].map(&:to_s).to_csv
        end
      end
    end

    def collect_statement_info(statement, directory)
      directory.open('statement.info.csv', 'w') do |file|
        file.puts ['Currency',
                   'Start Date',
                   'End Date',
                   'Amount of Transactions'].to_csv
        file.puts [statement.currency,
                   statement.start_date,
                   statement.end_date,
                   statement.transactions.size].map(&:to_s).to_csv
      end
    end

    def collect_bank_accounts(accounts, directory)
      accounts.each do |account|
        dir = directory.sub_dir "#{account.number}.bankaccount/#{account.statement.end_date}"
        dir.open('bank.info.csv', 'w') do |file|
          file.puts ['Account Number',
                     'Transaction UID',
                     'Routing Number',
                     'Balance',
                     'Balance in Minor Units',
                     'Blance Date'].to_csv
          file.puts [account.number,
                     account.transaction_uid,
                     account.routing_number,
                     account.balance.to_s,
                     account.balance_in_pennies,
                     account.balance_date].map(&:to_s).to_csv
        end
        collect_statement_info(account.statement, dir)
        collect_transactions(account.statement.transactions, dir)
      end
    end

    def collect_credit_accounts(accounts, directory)
      accounts.each do |account|
        dir = directory.sub_dir "#{account.number}.creditcard/#{account.statement.end_date}"
        dir.open('card.info.csv', 'w') do |file|
          file.puts ['Account Number',
                     'Transaction UID',
                     'Routing Number',
                     'Balance',
                     'Balance in Minor Units',
                     'Blance Date',
                     'Remaining Credit',
                     'Remaining Credit in Minor Units',
                     'Remaining Credit Date'].to_csv
          file.puts [account.number,
                     account.transaction_uid,
                     account.routing_number,
                     account.balance,
                     account.balance_in_pennies,
                     account.balance_date,
                     account.remaining_credit,
                     account.remaining_credit_in_pennies,
                     account.remaining_credit_date].map(&:to_s).to_csv
        end
        collect_statement_info(account.statement, dir)
        collect_transactions(account.statement.transactions, dir)
      end
    end

    def collect_account_info(account_info, directory)
      account_info.each do |info|
        directory.open('account.info.csv', 'w') do |file|
          file.puts ['Description', 'Account Number', 'Bank ID', 'Type'].map(&:to_s).to_csv
          file.puts [info.desc.to_title, info.number, info.bank_id, info.type].map(&:to_s).to_csv
        end
      end
    end
  end
end
