require 'csv'

require_relative 'extensions'

require 'rubygems'
require 'bundler/setup'
require 'active_support/inflector'
require 'path'

require_relative 'ofx-parser-fixes'


module OfxCsv

  EXTENSION = 'ofxcsv'

  class OfxCsv
    attr_reader :destination

    def initialize(destination)
      @destination = Path(destination).add_ext(EXTENSION).mkpath
    end

    def self.open(destination)
      self.new(destination)
    end

    def populate_with!(ofx_file_path)
      Path(ofx_file_path).open('r') do |file|
        ofx = OfxParser::OfxParser.parse file
        institute_path = destination / ofx.sign_on.institute.name
        collect_bank_accounts(ofx.bank_accounts, institute_path)
        collect_credit_accounts(ofx.credit_accounts, institute_path)
        collect_account_info(ofx.signup_account_info, institute_path)
      end
      destination.to_s
    end

    private

    using Extensions

    def collect_transactions(transactions, path)
      (path / 'statement.csv').open('w') do |file|
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

    def collect_statement_info(statement, path)
      (path / 'statement.info.csv').open('w') do |file|
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

    def collect_bank_accounts(accounts, path)
      accounts.each do |account|
        path = path / Path(account.number).add_ext('bankaccount') / account.statement.end_date
        (path.mkpath / 'bank.info.csv').open('w') do |file|
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
        collect_statement_info(account.statement, path)
        collect_transactions(account.statement.transactions, path)
      end
    end

    def collect_credit_accounts(accounts, path)
      accounts.each do |account|
        path = path / Path(account.number).add_ext('creditcard') / account.statement.end_date
        (path.mkpath / 'card.info.csv').open('w') do |file|
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
        collect_statement_info(account.statement, path)
        collect_transactions(account.statement.transactions, path)
      end
    end

    def collect_account_info(account_info, path)
      account_info.each do |info|
        (path / 'account.info.csv').open('w') do |file|
          file.puts ['Description', 'Account Number', 'Bank ID', 'Type'].map(&:to_s).to_csv
          file.puts [info.desc.to_title, info.number, info.bank_id, info.type].map(&:to_s).to_csv
        end
      end
    end
  end
end
