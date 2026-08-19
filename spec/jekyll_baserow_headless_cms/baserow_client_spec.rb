# frozen_string_literal: true

RSpec.describe JekyllBaserowHeadlessCMS::BaserowClient do
  let(:token) { 'test_database_token' }
  let(:client) { described_class.new(token) }
  let(:table_id) { 'test-table-id' }
  let(:rows_url) { "https://api.baserow.io/api/database/rows/table/#{table_id}/" }

  describe '#initialize' do
    it 'creates a client with a valid token' do
      expect { described_class.new(token) }.not_to raise_error
    end

    it 'raises an error with nil token' do
      expect { described_class.new(nil) }.to raise_error(JekyllBaserowHeadlessCMS::ConfigurationError)
    end

    it 'raises an error with empty token' do
      expect { described_class.new('') }.to raise_error(JekyllBaserowHeadlessCMS::ConfigurationError)
    end

    it 'defaults to the public Baserow API base URL' do
      stub_request(:get, rows_url)
        .with(query: hash_including('user_field_names' => 'true'))
        .to_return(status: 200, body: { 'results' => [], 'next' => nil }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { described_class.new(token).query_table(table_id) }.not_to raise_error
    end

    it 'uses a custom base URL when provided' do
      custom_client = described_class.new(token, base_url: 'https://baserow.example.com/')
      stub_request(:get, "https://baserow.example.com/api/database/rows/table/#{table_id}/")
        .with(query: hash_including('user_field_names' => 'true'))
        .to_return(status: 200, body: { 'results' => [], 'next' => nil }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { custom_client.query_table(table_id) }.not_to raise_error
    end
  end

  describe '#query_table' do
    let(:api_response) do
      {
        'count' => 2,
        'next' => nil,
        'previous' => nil,
        'results' => [
          { 'id' => 1, 'Title' => 'Row 1' },
          { 'id' => 2, 'Title' => 'Row 2' }
        ]
      }
    end

    before do
      stub_request(:get, rows_url)
        .with(
          query: hash_including('user_field_names' => 'true', 'size' => '200'),
          headers: {
            'Authorization' => "Token #{token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: api_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns results from the table' do
      result = client.query_table(table_id)
      expect(result['results'].length).to eq(2)
    end

    it 'includes all rows' do
      result = client.query_table(table_id)
      expect(result['results'].map { |r| r['id'] }).to eq([1, 2])
    end

    it 'passes order_by and filters through as query params' do
      stub_request(:get, rows_url)
        .with(query: hash_including('order_by' => '-order', 'filters' => 'featured'))
        .to_return(status: 200, body: api_response.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { client.query_table(table_id, order_by: '-order', filters: 'featured') }.not_to raise_error
    end

    context 'with pagination' do
      let(:next_page_url) { "#{rows_url}?user_field_names=true&size=200&page=2" }

      let(:page1_response) do
        {
          'count' => 2,
          'next' => next_page_url,
          'previous' => nil,
          'results' => [{ 'id' => 1, 'Title' => 'Row 1' }]
        }
      end

      let(:page2_response) do
        {
          'count' => 2,
          'next' => nil,
          'previous' => rows_url,
          'results' => [{ 'id' => 2, 'Title' => 'Row 2' }]
        }
      end

      before do
        stub_request(:get, rows_url)
          .with(query: hash_including('user_field_names' => 'true'))
          .to_return(status: 200, body: page1_response.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, next_page_url)
          .to_return(status: 200, body: page2_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'follows the next URL automatically' do
        result = client.query_table(table_id)
        expect(result['results'].length).to eq(2)
        expect(result['results'].map { |r| r['id'] }).to eq([1, 2])
      end
    end

    context 'with API errors' do
      it 'raises APIError for 401 Unauthorized' do
        stub_request(:get, rows_url)
          .with(query: hash_including('user_field_names' => 'true'))
          .to_return(status: 401, body: { 'error' => 'ERROR_INVALID_TOKEN', 'detail' => 'Invalid token' }.to_json)

        expect { client.query_table(table_id) }
          .to raise_error(JekyllBaserowHeadlessCMS::APIError, /401 Unauthorized/)
      end

      it 'raises APIError for 404 Not Found' do
        stub_request(:get, rows_url)
          .with(query: hash_including('user_field_names' => 'true'))
          .to_return(status: 404, body: { 'error' => 'ERROR_TABLE_DOES_NOT_EXIST' }.to_json)

        expect { client.query_table(table_id) }
          .to raise_error(JekyllBaserowHeadlessCMS::APIError, /404 Not Found/)
      end

      it 'raises APIError for 429 Rate Limited' do
        stub_request(:get, rows_url)
          .with(query: hash_including('user_field_names' => 'true'))
          .to_return(status: 429, body: { 'detail' => 'Rate limited' }.to_json)

        expect { client.query_table(table_id) }
          .to raise_error(JekyllBaserowHeadlessCMS::APIError, /429 Too Many Requests/)
      end

      it 'raises APIError with the parsed detail message for other errors' do
        stub_request(:get, rows_url)
          .with(query: hash_including('user_field_names' => 'true'))
          .to_return(status: 500, body: { 'detail' => 'Something went wrong' }.to_json)

        expect { client.query_table(table_id) }
          .to raise_error(JekyllBaserowHeadlessCMS::APIError, /Something went wrong/)
      end
    end
  end

  describe '#get_row' do
    let(:row_id) { 42 }
    let(:row_response) { { 'id' => row_id, 'Name' => 'Test' } }

    before do
      stub_request(:get, "https://api.baserow.io/api/database/rows/table/#{table_id}/#{row_id}/")
        .with(query: { 'user_field_names' => 'true' })
        .to_return(status: 200, body: row_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the row data' do
      result = client.get_row(table_id, row_id)
      expect(result['id']).to eq(row_id)
    end
  end
end
