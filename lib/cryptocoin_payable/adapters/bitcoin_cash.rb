require 'cash_addr'

module CryptocoinPayable
  module Adapters
    class BitcoinCash < Bitcoin
      def self.coin_symbol
        'BCH'
      end

      def fetch_transactions(address)
        raise NetworkNotSupported if CryptocoinPayable.configuration.testnet

        url = "https://explorer.api.bitcoin.com/bch/v1/txs?address=#{address}"
        parse_block_explorer_transactions(get_request(url).body, address)
      end

      def parse_block_explorer_transactions(response, address)
        json = JSON.parse(response)
        json['txs'].map { |tx| convert_explorer_api_transactions(tx, address) }
      rescue JSON::ParserError
        raise ApiError, response
      end

      def convert_explorer_api_transactions(transaction, address)
        {
          transaction_hash: transaction['txid'],
          block_hash: transaction['blockhash'],
          block_time: parse_timestamp(transaction['blocktime']),
          estimated_time: parse_timestamp(transaction['time']),
          estimated_value: parse_total_tx_value_block_explorer(transaction['vout'], address),
          confirmations: transaction['confirmations']
        }
      end

      def create_address(id)
        CashAddr::Converter.to_cash_address(super)
      end

      private

      def legacy_address(address)
        CashAddr::Converter.to_legacy_address(address)
      rescue CashAddr::InvalidAddress
        raise ApiError
      end

      def prefix
        CryptocoinPayable.configuration.testnet ? 'bchtest.' : 'bitcoincash.'
      end
    end
  end
end
