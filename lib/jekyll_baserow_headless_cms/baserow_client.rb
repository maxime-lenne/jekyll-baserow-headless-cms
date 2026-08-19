# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module JekyllBaserowHeadlessCMS
  # Client for interacting with the Baserow REST API
  class BaserowClient
    DEFAULT_API_BASE_URL = 'https://api.baserow.io'
    ROW_PAGE_SIZE = 200

    def initialize(token, base_url: nil)
      @token = token
      raise ConfigurationError, 'Baserow token is required' if @token.nil? || @token.empty?

      @base_url = (base_url && !base_url.empty? ? base_url : DEFAULT_API_BASE_URL).chomp('/')
    end

    # Query a Baserow table and return all rows
    # @param table_id [String, Integer] The ID of the table to query
    # @param order_by [String] Optional Baserow order_by expression (e.g. "field_name" or "-field_name")
    # @param filters [String] Optional Baserow filters expression (raw query string value)
    # @return [Hash] The API response with results
    def query_table(table_id, order_by: nil, filters: nil)
      all_results = []
      uri = build_rows_uri(table_id, order_by: order_by, filters: filters)

      loop do
        response = execute_request(uri, build_request(:get, uri))
        all_results.concat(response['results'])

        break unless response['next']

        uri = URI(response['next'])
      end

      { 'results' => all_results }
    end

    # Retrieve a single row
    # @param table_id [String, Integer] The ID of the table
    # @param row_id [String, Integer] The ID of the row to retrieve
    # @return [Hash] The row data
    def get_row(table_id, row_id)
      uri = URI("#{@base_url}/api/database/rows/table/#{table_id}/#{row_id}/")
      uri.query = URI.encode_www_form({ user_field_names: true })

      execute_request(uri, build_request(:get, uri))
    end

    private

    def build_rows_uri(table_id, order_by:, filters:)
      uri = URI("#{@base_url}/api/database/rows/table/#{table_id}/")
      params = { user_field_names: true, size: ROW_PAGE_SIZE }
      params[:order_by] = order_by if order_by
      params[:filters] = filters if filters
      uri.query = URI.encode_www_form(params)
      uri
    end

    def build_request(method, uri)
      request_class = case method
                      when :get then Net::HTTP::Get
                      else raise ArgumentError, "Unknown method: #{method}"
                      end

      request = request_class.new(uri)
      request['Authorization'] = "Token #{@token}"
      request['Content-Type'] = 'application/json'
      request
    end

    def execute_request(uri, request)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      handle_response(response)
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPUnauthorized
        raise APIError, 'Invalid Baserow token (401 Unauthorized)'
      when Net::HTTPNotFound
        raise APIError, 'Table or row not found (404 Not Found)'
      when Net::HTTPTooManyRequests
        raise APIError, 'Rate limit exceeded (429 Too Many Requests)'
      else
        error_message = parse_error_message(response)
        raise APIError, "Baserow API error: #{response.code} #{error_message}"
      end
    end

    def parse_error_message(response)
      error_json = JSON.parse(response.body)
      error_json['detail'] || error_json['error'] || response.message
    rescue JSON::ParserError
      response.message
    end
  end
end
