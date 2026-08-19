# frozen_string_literal: true

RSpec.describe JekyllBaserowHeadlessCMS::FieldExtractors do
  describe '.extract' do
    describe 'text field' do
      it 'extracts text value' do
        row = { 'Name' => 'Hello World' }
        expect(described_class.extract(row, 'Name', 'text')).to eq('Hello World')
      end

      it 'returns nil for missing field' do
        row = {}
        expect(described_class.extract(row, 'Missing', 'text')).to be_nil
      end

      it 'returns nil for empty string' do
        row = { 'Name' => '' }
        expect(described_class.extract(row, 'Name', 'text')).to be_nil
      end

      it 'returns nil for null value' do
        row = { 'Name' => nil }
        expect(described_class.extract(row, 'Name', 'text')).to be_nil
      end
    end

    describe 'long_text field' do
      it 'extracts long text value' do
        row = { 'Description' => 'Some longer text' }
        expect(described_class.extract(row, 'Description', 'long_text')).to eq('Some longer text')
      end
    end

    describe 'number field' do
      it 'extracts integer number value' do
        row = { 'Level' => 42 }
        expect(described_class.extract(row, 'Level', 'number')).to eq(42)
      end

      it 'extracts float number value' do
        row = { 'Level' => 4.5 }
        expect(described_class.extract(row, 'Level', 'number')).to eq(4.5)
      end

      it 'parses integer values returned as strings' do
        row = { 'Level' => '42' }
        expect(described_class.extract(row, 'Level', 'number')).to eq(42)
      end

      it 'parses decimal values returned as strings' do
        row = { 'Level' => '4.50' }
        expect(described_class.extract(row, 'Level', 'number')).to eq(4.5)
      end

      it 'returns nil for null value' do
        row = { 'Level' => nil }
        expect(described_class.extract(row, 'Level', 'number')).to be_nil
      end
    end

    describe 'rating and count fields' do
      it 'extracts rating value' do
        row = { 'Rating' => 5 }
        expect(described_class.extract(row, 'Rating', 'rating')).to eq(5)
      end

      it 'extracts count value' do
        row = { 'Linked Count' => 3 }
        expect(described_class.extract(row, 'Linked Count', 'count')).to eq(3)
      end
    end

    describe 'boolean field' do
      it 'extracts true boolean' do
        row = { 'Featured' => true }
        expect(described_class.extract(row, 'Featured', 'boolean')).to be true
      end

      it 'extracts false boolean' do
        row = { 'Featured' => false }
        expect(described_class.extract(row, 'Featured', 'boolean')).to be false
      end

      it 'returns nil for a field that is entirely missing' do
        row = { 'Other' => true }
        expect(described_class.extract(row, 'Featured', 'boolean')).to be_nil
      end

      it 'returns false for a null value' do
        row = { 'Featured' => nil }
        expect(described_class.extract(row, 'Featured', 'boolean')).to be false
      end
    end

    describe 'date, created_on and last_modified fields' do
      it 'extracts a date string' do
        row = { 'Start Date' => '2024-01-15' }
        expect(described_class.extract(row, 'Start Date', 'date')).to eq('2024-01-15')
      end

      it 'extracts a datetime string' do
        row = { 'Created' => '2024-01-15T10:30:00Z' }
        expect(described_class.extract(row, 'Created', 'created_on')).to eq('2024-01-15T10:30:00Z')
      end

      it 'extracts last_modified' do
        row = { 'Updated' => '2024-01-20T15:45:00Z' }
        expect(described_class.extract(row, 'Updated', 'last_modified')).to eq('2024-01-20T15:45:00Z')
      end

      it 'returns nil for null date' do
        row = { 'Start Date' => nil }
        expect(described_class.extract(row, 'Start Date', 'date')).to be_nil
      end
    end

    describe 'single_select field' do
      it 'extracts the option value' do
        row = { 'Status' => { 'id' => 1, 'value' => 'Published', 'color' => 'green' } }
        expect(described_class.extract(row, 'Status', 'single_select')).to eq('Published')
      end

      it 'returns nil for a null select' do
        row = { 'Status' => nil }
        expect(described_class.extract(row, 'Status', 'single_select')).to be_nil
      end
    end

    describe 'multi_select field' do
      it 'extracts an array of option values' do
        row = {
          'Tags' => [
            { 'id' => 1, 'value' => 'Ruby', 'color' => 'red' },
            { 'id' => 2, 'value' => 'Jekyll', 'color' => 'blue' }
          ]
        }
        expect(described_class.extract(row, 'Tags', 'multi_select')).to eq(%w[Ruby Jekyll])
      end

      it 'returns an empty array for an empty selection' do
        row = { 'Tags' => [] }
        expect(described_class.extract(row, 'Tags', 'multi_select')).to eq([])
      end

      it 'returns an empty array for a null value' do
        row = { 'Tags' => nil }
        expect(described_class.extract(row, 'Tags', 'multi_select')).to eq([])
      end
    end

    describe 'url, email and phone_number fields' do
      it 'extracts a url' do
        row = { 'Link' => 'https://example.com' }
        expect(described_class.extract(row, 'Link', 'url')).to eq('https://example.com')
      end

      it 'extracts an email' do
        row = { 'Email' => 'test@example.com' }
        expect(described_class.extract(row, 'Email', 'email')).to eq('test@example.com')
      end

      it 'extracts a phone number' do
        row = { 'Phone' => '+33612345678' }
        expect(described_class.extract(row, 'Phone', 'phone_number')).to eq('+33612345678')
      end

      it 'returns nil for empty string values' do
        row = { 'Link' => '' }
        expect(described_class.extract(row, 'Link', 'url')).to be_nil
      end
    end

    describe 'link_row field' do
      it 'extracts an array of linked row id/name pairs' do
        row = {
          'Category' => [
            { 'id' => 1, 'value' => 'Backend' },
            { 'id' => 2, 'value' => 'Frontend' }
          ]
        }
        result = described_class.extract(row, 'Category', 'link_row')
        expect(result).to eq([{ 'id' => 1, 'name' => 'Backend' }, { 'id' => 2, 'name' => 'Frontend' }])
      end

      it 'returns an empty array for a null value' do
        row = { 'Category' => nil }
        expect(described_class.extract(row, 'Category', 'link_row')).to eq([])
      end
    end

    describe 'lookup and formula_array fields' do
      it 'returns a single value when the lookup has one result' do
        row = { 'Category' => [{ 'id' => 1, 'value' => 'Backend' }] }
        expect(described_class.extract(row, 'Category', 'lookup')).to eq('Backend')
      end

      it 'returns an array when the lookup has multiple results' do
        row = { 'Categories' => [{ 'id' => 1, 'value' => 'Backend' }, { 'id' => 2, 'value' => 'Frontend' }] }
        expect(described_class.extract(row, 'Categories', 'lookup')).to eq(%w[Backend Frontend])
      end

      it 'returns nil for an empty lookup array' do
        row = { 'Category' => [] }
        expect(described_class.extract(row, 'Category', 'lookup')).to be_nil
      end

      it 'returns nil for a null lookup' do
        row = { 'Category' => nil }
        expect(described_class.extract(row, 'Category', 'lookup')).to be_nil
      end

      it 'filters out nil values from multiple lookup items' do
        row = { 'Mixed' => [{ 'id' => 1, 'value' => 'Valid' }, { 'id' => 2, 'value' => nil }] }
        expect(described_class.extract(row, 'Mixed', 'lookup')).to eq('Valid')
      end

      it 'treats formula_array the same way as lookup' do
        row = { 'Computed' => [{ 'id' => 1, 'value' => 'A' }, { 'id' => 2, 'value' => 'B' }] }
        expect(described_class.extract(row, 'Computed', 'formula_array')).to eq(%w[A B])
      end
    end

    describe 'formula field' do
      it 'returns the raw scalar value' do
        row = { 'Computed' => 'result' }
        expect(described_class.extract(row, 'Computed', 'formula')).to eq('result')
      end

      it 'returns a numeric value as-is' do
        row = { 'Computed' => 42 }
        expect(described_class.extract(row, 'Computed', 'formula')).to eq(42)
      end
    end

    describe 'file field' do
      it 'extracts an array of file objects' do
        row = {
          'Attachment' => [
            { 'name' => 'document.pdf', 'url' => 'https://baserow.io/files/document.pdf', 'mime_type' => 'application/pdf' }
          ]
        }
        result = described_class.extract(row, 'Attachment', 'file')
        expect(result).to eq([
                               { 'name' => 'document.pdf', 'url' => 'https://baserow.io/files/document.pdf',
                                 'type' => 'application/pdf' }
                             ])
      end

      it 'returns an empty array for a null value' do
        row = { 'Attachment' => nil }
        expect(described_class.extract(row, 'Attachment', 'file')).to eq([])
      end
    end

    describe 'unknown field type' do
      it 'returns nil for an unhandled type' do
        row = { 'Unknown' => 'value' }
        expect(described_class.extract(row, 'Unknown', 'unknown_type')).to be_nil
      end
    end
  end

  describe '.extract_all' do
    let(:row) do
      {
        'id' => 1,
        'Title' => 'Test Item',
        'Level' => 85,
        'Featured' => true
      }
    end

    let(:config) do
      [
        { 'name' => 'Title', 'type' => 'text' },
        { 'name' => 'Level', 'type' => 'number' },
        { 'name' => 'Featured', 'type' => 'boolean' }
      ]
    end

    it 'extracts all configured fields' do
      result = described_class.extract_all(row, config)
      expect(result['title']).to eq('Test Item')
      expect(result['level']).to eq(85)
      expect(result['featured']).to be true
    end

    it 'uses custom key when specified' do
      config[0]['key'] = 'name'
      result = described_class.extract_all(row, config)
      expect(result['name']).to eq('Test Item')
    end

    it 'falls back to name when title is not present' do
      row = { 'Name' => 'Item Name', 'Level' => 85 }
      config = [
        { 'name' => 'Name', 'type' => 'text', 'key' => 'name' },
        { 'name' => 'Level', 'type' => 'number' }
      ]
      result = described_class.extract_all(row, config)
      expect(result['title']).to eq('Item Name')
      expect(result['name']).to eq('Item Name')
    end

    it 'does not overwrite existing title with name' do
      row = { 'Title' => 'Actual Title', 'Name' => 'Different Name' }
      config = [
        { 'name' => 'Title', 'type' => 'text' },
        { 'name' => 'Name', 'type' => 'text', 'key' => 'name' }
      ]
      result = described_class.extract_all(row, config)
      expect(result['title']).to eq('Actual Title')
      expect(result['name']).to eq('Different Name')
    end

    it 'handles missing fields gracefully' do
      row = { 'Title' => 'Test' }
      config = [
        { 'name' => 'Title', 'type' => 'text' },
        { 'name' => 'Missing', 'type' => 'number' }
      ]
      result = described_class.extract_all(row, config)
      expect(result['title']).to eq('Test')
      expect(result['missing']).to be_nil
    end
  end

  describe '.normalize_key' do
    it 'converts to lowercase' do
      expect(described_class.normalize_key('Title')).to eq('title')
    end

    it 'replaces spaces with underscores' do
      expect(described_class.normalize_key('Start Date')).to eq('start_date')
    end

    it 'handles multiple spaces' do
      expect(described_class.normalize_key('Some  Long  Name')).to eq('some_long_name')
    end
  end
end
