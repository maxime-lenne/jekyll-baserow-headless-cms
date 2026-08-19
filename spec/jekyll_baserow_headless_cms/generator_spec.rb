# frozen_string_literal: true

RSpec.describe JekyllBaserowHeadlessCMS::Generator do
  let(:site) { instance_double(Jekyll::Site) }
  let(:source_dir) { '/tmp/jekyll_baserow_test_site' }
  let(:data_dir) { File.join(source_dir, '_data') }
  let(:generator) { described_class.new }

  before do
    allow(site).to receive_messages(source: source_dir, data: {}, config: {}, collections: {})
    allow(Jekyll.logger).to receive(:info)
    allow(Jekyll.logger).to receive(:warn)
    allow(Jekyll.logger).to receive(:error)
    FileUtils.rm_rf(data_dir)
  end

  after do
    FileUtils.rm_rf(data_dir)
  end

  describe '#generate' do
    context 'when plugin is disabled' do
      before do
        allow(site).to receive(:config).and_return({ 'baserow' => { 'enabled' => false } })
      end

      it 'logs that the plugin is disabled' do
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:', 'Plugin disabled in configuration')
        generator.generate(site)
      end

      it 'does not fetch data' do
        expect(JekyllBaserowHeadlessCMS::BaserowClient).not_to receive(:new)
        generator.generate(site)
      end
    end

    context 'when BASEROW_TOKEN is missing' do
      let(:config) do
        {
          'baserow' => {
            'collections' => {
              'posts' => { 'table_env' => 'POSTS_TABLE', 'data_file' => 'posts.yml', 'fields' => [] }
            }
          }
        }
      end

      before do
        allow(site).to receive(:config).and_return(config)
        ENV.delete('BASEROW_TOKEN')
      end

      it 'logs that no token was found' do
        expect(Jekyll.logger).to receive(:info)
          .with('BaserowCMS:', 'No BASEROW_TOKEN found, using collections fallback')
        generator.generate(site)
      end

      it 'uses fallback for all collections' do
        FileUtils.mkdir_p(data_dir)
        generator.generate(site)
        expect(File.exist?(File.join(data_dir, 'posts.yml'))).to be true
      end
    end

    context 'when BASEROW_TOKEN exists' do
      let(:baserow_client) { instance_double(JekyllBaserowHeadlessCMS::BaserowClient) }
      let(:baserow_response) do
        {
          'results' => [
            { 'id' => 1, 'Title' => 'Test Post' }
          ]
        }
      end
      let(:config) do
        {
          'baserow' => {
            'collections' => {
              'posts' => {
                'table_env' => 'POSTS_TABLE',
                'data_file' => 'posts.yml',
                'fields' => [{ 'name' => 'Title', 'type' => 'text' }]
              }
            }
          }
        }
      end

      before do
        ENV['BASEROW_TOKEN'] = 'test_token'
        ENV['POSTS_TABLE'] = 'table_123'
        allow(site).to receive(:config).and_return(config)
        allow(JekyllBaserowHeadlessCMS::BaserowClient).to receive(:new)
          .with('test_token', base_url: nil).and_return(baserow_client)
        allow(baserow_client).to receive(:query_table).with('table_123').and_return(baserow_response)
      end

      after do
        ENV.delete('BASEROW_TOKEN')
        ENV.delete('POSTS_TABLE')
      end

      it 'creates a BaserowClient' do
        expect(JekyllBaserowHeadlessCMS::BaserowClient).to receive(:new).with('test_token', base_url: nil)
        generator.generate(site)
      end

      it 'fetches data from each configured collection' do
        expect(baserow_client).to receive(:query_table).with('table_123')
        generator.generate(site)
      end

      it 'logs success message' do
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:', 'All data fetched successfully')
        generator.generate(site)
      end

      it 'writes data to site.data' do
        generator.generate(site)
        expect(site.data['posts']).to be_an(Array)
      end

      it 'creates data file' do
        FileUtils.mkdir_p(data_dir)
        generator.generate(site)
        expect(File.exist?(File.join(data_dir, 'posts.yml'))).to be true
      end
    end

    context 'when API error occurs during collection fetch' do
      let(:baserow_client) { instance_double(JekyllBaserowHeadlessCMS::BaserowClient) }
      let(:config) do
        {
          'baserow' => {
            'collections' => {
              'posts' => {
                'table_env' => 'POSTS_TABLE',
                'data_file' => 'posts.yml',
                'fields' => []
              }
            }
          }
        }
      end

      before do
        ENV['BASEROW_TOKEN'] = 'test_token'
        ENV['POSTS_TABLE'] = 'table_123'
        FileUtils.mkdir_p(data_dir)
        allow(site).to receive(:config).and_return(config)
        allow(JekyllBaserowHeadlessCMS::BaserowClient).to receive(:new).and_return(baserow_client)
        allow(baserow_client).to receive(:query_table).and_raise(StandardError, 'API Error')
      end

      after do
        ENV.delete('BASEROW_TOKEN')
        ENV.delete('POSTS_TABLE')
      end

      it 'logs the error per collection' do
        expect(Jekyll.logger).to receive(:error).with('BaserowCMS:', 'Error fetching posts: API Error')
        generator.generate(site)
      end

      it 'uses collection fallback' do
        generator.generate(site)
        expect(site.data['posts']).to eq([])
      end
    end

    context 'when client initialization fails' do
      let(:config) do
        {
          'baserow' => {
            'collections' => {
              'posts' => {
                'table_env' => 'POSTS_TABLE',
                'data_file' => 'posts.yml',
                'fields' => []
              }
            }
          }
        }
      end

      before do
        ENV['BASEROW_TOKEN'] = 'test_token'
        FileUtils.mkdir_p(data_dir)
        allow(site).to receive(:config).and_return(config)
        allow(JekyllBaserowHeadlessCMS::BaserowClient).to receive(:new).and_raise(StandardError, 'Connection failed')
      end

      after do
        ENV.delete('BASEROW_TOKEN')
      end

      it 'logs the error' do
        expect(Jekyll.logger).to receive(:error).with('BaserowCMS:', 'Error fetching data: Connection failed')
        generator.generate(site)
      end

      it 'falls back to all collections' do
        expect(Jekyll.logger).to receive(:warn).with('BaserowCMS:', 'Falling back to collections')
        generator.generate(site)
      end
    end
  end

  describe '#fetch_collection_data' do
    let(:baserow_client) { instance_double(JekyllBaserowHeadlessCMS::BaserowClient) }
    let(:config) do
      {
        'table_env' => 'TEST_TABLE',
        'data_file' => 'test.yml',
        'fields' => [{ 'name' => 'Title', 'type' => 'text' }]
      }
    end
    let(:baserow_response) do
      { 'results' => [{ 'id' => 1, 'Title' => 'Test' }] }
    end

    before do
      ENV['BASEROW_TOKEN'] = 'test_token'
      allow(site).to receive(:config).and_return({ 'baserow' => { 'collections' => {} } })
      allow(JekyllBaserowHeadlessCMS::BaserowClient).to receive(:new).and_return(baserow_client)
    end

    after do
      ENV.delete('BASEROW_TOKEN')
      ENV.delete('TEST_TABLE')
    end

    context 'when table_id is missing' do
      it 'uses fallback' do
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:',
                                                     'No TEST_TABLE found, using fallback for test_collection')
        generator.generate(site)
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when table_id starts with example_' do
      before do
        ENV['TEST_TABLE'] = 'example_table_123'
      end

      it 'uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:',
                                                     'No TEST_TABLE found, using fallback for test_collection')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when table_id is empty' do
      before do
        ENV['TEST_TABLE'] = ''
      end

      it 'uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:',
                                                     'No TEST_TABLE found, using fallback for test_collection')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when API returns empty results' do
      before do
        ENV['TEST_TABLE'] = 'table_123'
        allow(baserow_client).to receive(:query_table).and_return({ 'results' => [] })
      end

      it 'uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:warn)
          .with('BaserowCMS:', 'No data found for test_collection, using fallback')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when API call fails' do
      before do
        ENV['TEST_TABLE'] = 'table_123'
        allow(baserow_client).to receive(:query_table).and_raise(StandardError, 'Connection error')
      end

      it 'logs error and uses fallback' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:error).with('BaserowCMS:', 'Error fetching test_collection: Connection error')
        generator.send(:fetch_collection_data, 'test_collection', config)
      end
    end

    context 'when organized data is a hash' do
      let(:config_with_grouping) do
        {
          'table_env' => 'TEST_TABLE',
          'data_file' => 'test.yml',
          'organizer' => 'grouped_by',
          'group_by' => 'category',
          'fields' => [
            { 'name' => 'Title', 'type' => 'text' },
            { 'name' => 'Category', 'type' => 'single_select' }
          ]
        }
      end
      let(:grouped_response) do
        {
          'results' => [
            { 'id' => 1, 'Title' => 'Test', 'Category' => { 'id' => 1, 'value' => 'Tech' } }
          ]
        }
      end

      before do
        ENV['TEST_TABLE'] = 'table_123'
        allow(baserow_client).to receive(:query_table).and_return(grouped_response)
      end

      it 'counts items correctly for hash data' do
        generator.generate(site)
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:', match(/test_collection fetched \(\d+ items\)/))
        generator.send(:fetch_collection_data, 'test_collection', config_with_grouping)
      end
    end
  end

  describe '#create_data_file' do
    let(:data) { [{ 'title' => 'Test' }] }
    let(:file_name) { 'test.yml' }
    let(:collection_name) { 'test' }

    before do
      FileUtils.mkdir_p(data_dir)
      allow(site).to receive(:config).and_return({ 'baserow' => { 'collections' => {} } })
      generator.generate(site)
    end

    it 'creates the _data directory if it does not exist' do
      FileUtils.rm_rf(data_dir)
      generator.send(:create_data_file, data, file_name, collection_name)
      expect(Dir.exist?(data_dir)).to be true
    end

    it 'writes data to file' do
      generator.send(:create_data_file, data, file_name, collection_name)
      expect(File.exist?(File.join(data_dir, file_name))).to be true
    end

    it 'includes header comments' do
      generator.send(:create_data_file, data, file_name, collection_name)
      content = File.read(File.join(data_dir, file_name))
      expect(content).to include('# Test data imported from Baserow')
      expect(content).to include('# Auto-generated by jekyll-baserow-headless-cms')
      expect(content).to include('# Last updated:')
    end

    it 'includes YAML data' do
      generator.send(:create_data_file, data, file_name, collection_name)
      content = File.read(File.join(data_dir, file_name))
      expect(content).to include('title: Test')
    end

    context 'when content is unchanged' do
      it 'skips writing' do
        generator.send(:create_data_file, data, file_name, collection_name)
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:', 'test data unchanged, skipping')
        generator.send(:create_data_file, data, file_name, collection_name)
      end
    end

    context 'when content has changed' do
      it 'writes new content' do
        generator.send(:create_data_file, data, file_name, collection_name)
        new_data = [{ 'title' => 'Updated' }]
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:', "test written to _data/#{file_name}")
        generator.send(:create_data_file, new_data, file_name, collection_name)
      end
    end
  end

  describe '#use_collection_fallback' do
    let(:config) do
      {
        'data_file' => 'posts.yml',
        'fields' => [
          { 'name' => 'Title', 'type' => 'text' },
          { 'name' => 'Order', 'type' => 'number' }
        ]
      }
    end

    before do
      FileUtils.mkdir_p(data_dir)
      allow(site).to receive(:config).and_return({ 'baserow' => { 'collections' => {} } })
      generator.generate(site)
    end

    context 'when Jekyll collection exists' do
      let(:doc1) do
        instance_double(
          Jekyll::Document,
          data: { 'title' => 'Post 1', 'order' => 1 }
        )
      end
      let(:doc2) do
        instance_double(
          Jekyll::Document,
          data: { 'title' => 'Post 2', 'order' => 2 }
        )
      end
      let(:collection) { instance_double(Jekyll::Collection, docs: [doc1, doc2]) }

      before do
        allow(site).to receive(:collections).and_return({ 'posts' => collection })
      end

      it 'converts Jekyll docs to Baserow row format' do
        generator.send(:use_collection_fallback, 'posts', config)
        expect(site.data['posts']).to be_an(Array)
      end

      it 'includes document data' do
        generator.send(:use_collection_fallback, 'posts', config)
        expect(site.data['posts'].length).to eq(2)
      end

      it 'logs the fallback count' do
        expect(Jekyll.logger).to receive(:info).with('BaserowCMS:', 'posts fallback applied (2 items)')
        generator.send(:use_collection_fallback, 'posts', config)
      end
    end

    context 'when Jekyll collection does not exist' do
      it 'creates empty data' do
        generator.send(:use_collection_fallback, 'nonexistent', config)
        expect(site.data['posts']).to eq([])
      end
    end

    context 'with .yaml extension' do
      let(:yaml_config) do
        {
          'data_file' => 'posts.yaml',
          'fields' => []
        }
      end

      it 'handles .yaml extension correctly' do
        generator.send(:use_collection_fallback, 'posts', yaml_config)
        expect(site.data['posts']).to eq([])
      end
    end
  end

  describe '#convert_doc_to_fields' do
    let(:fields_config) do
      [
        { 'name' => 'Title', 'type' => 'text' },
        { 'name' => 'Description', 'type' => 'long_text', 'key' => 'desc' },
        { 'name' => 'Order', 'type' => 'number' }
      ]
    end

    before do
      allow(site).to receive(:config).and_return({ 'baserow' => { 'collections' => {} } })
      generator.generate(site)
    end

    it 'converts document data to Baserow field values' do
      data = { 'title' => 'Test', 'desc' => 'Description', 'order' => 1 }
      result = generator.send(:convert_doc_to_fields, data, fields_config)

      expect(result['Title']).to eq('Test')
      expect(result['Order']).to eq(1)
    end

    it 'uses custom key when specified' do
      data = { 'desc' => 'Custom description' }
      result = generator.send(:convert_doc_to_fields, data, fields_config)

      expect(result['Description']).to eq('Custom description')
    end

    it 'tries lowercase field name as fallback' do
      data = { 'title' => 'Lowercase key' }
      result = generator.send(:convert_doc_to_fields, data, fields_config)

      expect(result['Title']).to eq('Lowercase key')
    end

    it 'tries original field name as final fallback' do
      data = { 'Title' => 'Original key' }
      result = generator.send(:convert_doc_to_fields, data, fields_config)

      expect(result['Title']).to eq('Original key')
    end

    it 'skips nil values' do
      data = { 'title' => nil }
      result = generator.send(:convert_doc_to_fields, data, fields_config)

      expect(result).not_to have_key('Title')
    end
  end

  describe '#convert_value_to_baserow_field' do
    before do
      allow(site).to receive(:config).and_return({ 'baserow' => { 'collections' => {} } })
      generator.generate(site)
    end

    it 'converts text values to strings' do
      result = generator.send(:convert_value_to_baserow_field, 123, 'text')
      expect(result).to eq('123')
    end

    it 'converts number type' do
      result = generator.send(:convert_value_to_baserow_field, '42', 'number')
      expect(result).to eq(42)
    end

    it 'converts boolean type with true' do
      result = generator.send(:convert_value_to_baserow_field, true, 'boolean')
      expect(result).to be true
    end

    it 'converts boolean type with false' do
      result = generator.send(:convert_value_to_baserow_field, false, 'boolean')
      expect(result).to be false
    end

    it 'converts boolean type with a truthy value' do
      result = generator.send(:convert_value_to_baserow_field, 'yes', 'boolean')
      expect(result).to be true
    end

    it 'converts single_select type' do
      result = generator.send(:convert_value_to_baserow_field, 'Option A', 'single_select')
      expect(result).to eq({ 'id' => nil, 'value' => 'Option A', 'color' => nil })
    end

    it 'converts multi_select type with an array' do
      result = generator.send(:convert_value_to_baserow_field, %w[Tag1 Tag2], 'multi_select')
      expect(result.length).to eq(2)
      expect(result.first).to eq({ 'id' => nil, 'value' => 'Tag1', 'color' => nil })
    end

    it 'converts multi_select type with a single value' do
      result = generator.send(:convert_value_to_baserow_field, 'SingleTag', 'multi_select')
      expect(result.length).to eq(1)
      expect(result.first['value']).to eq('SingleTag')
    end

    it 'defaults to a string for unknown types' do
      result = generator.send(:convert_value_to_baserow_field, 'unknown', 'unknown_type')
      expect(result).to eq('unknown')
    end
  end

  describe '#use_all_collections_fallback' do
    let(:config) do
      {
        'baserow' => {
          'collections' => {
            'posts' => { 'data_file' => 'posts.yml', 'fields' => [] },
            'projects' => { 'data_file' => 'projects.yml', 'fields' => [] }
          }
        }
      }
    end

    before do
      FileUtils.mkdir_p(data_dir)
      allow(site).to receive(:config).and_return(config)
    end

    it 'applies fallback to all collections' do
      ENV.delete('BASEROW_TOKEN')
      generator.generate(site)

      expect(site.data['posts']).to eq([])
      expect(site.data['projects']).to eq([])
    end

    it 'creates data files for all collections' do
      ENV.delete('BASEROW_TOKEN')
      generator.generate(site)

      expect(File.exist?(File.join(data_dir, 'posts.yml'))).to be true
      expect(File.exist?(File.join(data_dir, 'projects.yml'))).to be true
    end
  end
end
