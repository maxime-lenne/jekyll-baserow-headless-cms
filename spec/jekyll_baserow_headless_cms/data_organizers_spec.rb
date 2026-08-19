# frozen_string_literal: true

RSpec.describe JekyllBaserowHeadlessCMS::DataOrganizers do
  let(:baserow_data) do
    {
      'results' => [
        { 'id' => 1, 'Title' => 'Item A', 'Order' => 2 },
        { 'id' => 2, 'Title' => 'Item B', 'Order' => 1 }
      ]
    }
  end

  let(:fields_config) do
    [
      { 'name' => 'Title', 'type' => 'text' },
      { 'name' => 'Order', 'type' => 'number' }
    ]
  end

  describe '.organize' do
    it 'defaults to simple_list organizer' do
      config = { 'fields' => fields_config }
      result = described_class.organize(baserow_data, config)
      expect(result).to be_an(Array)
    end

    it 'uses specified organizer' do
      config = { 'organizer' => 'simple_list', 'fields' => fields_config }
      result = described_class.organize(baserow_data, config)
      expect(result).to be_an(Array)
    end
  end

  describe '.organize_simple_list' do
    it 'returns an array of items' do
      result = described_class.organize_simple_list(baserow_data, fields_config, nil, 'asc')
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'includes the row id' do
      result = described_class.organize_simple_list(baserow_data, fields_config, nil, 'asc')
      expect(result.first['id']).to eq(1)
    end

    it 'sorts by specified field ascending' do
      result = described_class.organize_simple_list(baserow_data, fields_config, 'order', 'asc')
      expect(result.first['title']).to eq('Item B')
      expect(result.last['title']).to eq('Item A')
    end

    it 'sorts by specified field descending' do
      result = described_class.organize_simple_list(baserow_data, fields_config, 'order', 'desc')
      expect(result.first['title']).to eq('Item A')
      expect(result.last['title']).to eq('Item B')
    end

    it 'filters out items without a title' do
      baserow_data['results'] << { 'id' => 3, 'Title' => nil, 'Order' => 3 }
      result = described_class.organize_simple_list(baserow_data, fields_config, nil, 'asc')
      expect(result.length).to eq(2)
    end
  end

  describe '.organize_items_by_category' do
    let(:items_data) do
      {
        'results' => [
          {
            'id' => 1,
            'Name' => 'Ruby',
            'Level' => 90,
            'Category' => [{ 'id' => 10, 'value' => 'Backend' }],
            'Order' => 1
          },
          {
            'id' => 2,
            'Name' => 'Python',
            'Level' => 85,
            'Category' => [{ 'id' => 10, 'value' => 'Backend' }],
            'Order' => 2
          },
          {
            'id' => 3,
            'Name' => 'React',
            'Level' => 80,
            'Category' => [{ 'id' => 11, 'value' => 'Frontend' }],
            'Order' => 1
          }
        ]
      }
    end

    it 'groups items by category' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result.keys).to contain_exactly('Backend', 'Frontend')
    end

    it 'includes category metadata' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result['Backend']['title']).to eq('Backend')
      expect(result['Backend']['category']).to eq('Backend')
    end

    it 'includes items in each category' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result['Backend']['items'].length).to eq(2)
      expect(result['Frontend']['items'].length).to eq(1)
    end

    it 'sorts items within categories by order' do
      result = described_class.organize_items_by_category(items_data, [])
      expect(result['Backend']['items'].first['name']).to eq('Ruby')
    end

    context 'when category order lookup returns multiple values (array)' do
      let(:items_with_array_order) do
        {
          'results' => [
            {
              'id' => 1,
              'Name' => 'Ruby',
              'Level' => 90,
              'Category' => [{ 'id' => 10, 'value' => 'Backend' }],
              'Category Order' => [{ 'id' => 10, 'value' => 2 }, { 'id' => 12, 'value' => 3 }],
              'Order' => 1
            },
            {
              'id' => 2,
              'Name' => 'React',
              'Level' => 80,
              'Category' => [{ 'id' => 11, 'value' => 'Frontend' }],
              'Category Order' => [{ 'id' => 11, 'value' => 1 }, { 'id' => 13, 'value' => 4 }],
              'Order' => 1
            }
          ]
        }
      end

      it 'handles array values for category order when sorting' do
        result = described_class.organize_items_by_category(items_with_array_order, [])
        categories = result.keys
        expect(categories.first).to eq('Frontend')
        expect(categories.last).to eq('Backend')
      end

      it 'extracts the first value from the array for category order' do
        result = described_class.organize_items_by_category(items_with_array_order, [])
        expect(result['Frontend']['order']).to eq(1)
        expect(result['Backend']['order']).to eq(2)
      end
    end
  end

  describe '.organize_grouped_by' do
    let(:grouped_data) do
      {
        'results' => [
          { 'id' => 1, 'Title' => 'Post A', 'Category' => { 'id' => 1, 'value' => 'Tech' }, 'Order' => 1 },
          { 'id' => 2, 'Title' => 'Post B', 'Category' => { 'id' => 1, 'value' => 'Tech' }, 'Order' => 2 },
          { 'id' => 3, 'Title' => 'Post C', 'Category' => { 'id' => 2, 'value' => 'Design' }, 'Order' => 1 }
        ]
      }
    end

    let(:grouped_config) do
      [
        { 'name' => 'Title', 'type' => 'text' },
        { 'name' => 'Category', 'type' => 'single_select' },
        { 'name' => 'Order', 'type' => 'number' }
      ]
    end

    it 'groups items by specified field' do
      result = described_class.organize_grouped_by(grouped_data, grouped_config, 'category', 'order', 'asc')
      expect(result.keys).to contain_exactly('Tech', 'Design')
    end

    it 'includes correct items in each group' do
      result = described_class.organize_grouped_by(grouped_data, grouped_config, 'category', 'order', 'asc')
      expect(result['Tech'].length).to eq(2)
      expect(result['Design'].length).to eq(1)
    end
  end

  describe '.organize_nested' do
    let(:nested_data) do
      {
        'results' => [
          { 'id' => 1, 'Title' => 'Root', 'Parent' => nil, 'Order' => 1 },
          { 'id' => 2, 'Title' => 'Child', 'Parent' => 1, 'Order' => 1 }
        ]
      }
    end

    let(:nested_config) do
      [
        { 'name' => 'Title', 'type' => 'text' },
        { 'name' => 'Parent', 'type' => 'number', 'key' => 'parent_id' },
        { 'name' => 'Order', 'type' => 'number' }
      ]
    end

    it 'builds a tree from parent references' do
      result = described_class.organize_nested(nested_data, nested_config, 'parent_id', nil, 'asc')
      expect(result.length).to eq(1)
      expect(result.first['title']).to eq('Root')
      expect(result.first['children'].first['title']).to eq('Child')
    end
  end

  describe '.data_present?' do
    it 'returns false for nil' do
      expect(described_class.data_present?(nil)).to be false
    end

    it 'returns false for empty array' do
      expect(described_class.data_present?([])).to be false
    end

    it 'returns false for empty hash' do
      expect(described_class.data_present?({})).to be false
    end

    it 'returns true for non-empty array' do
      expect(described_class.data_present?([1])).to be true
    end

    it 'returns true for non-empty hash' do
      expect(described_class.data_present?({ a: 1 })).to be true
    end
  end
end
