# frozen_string_literal: true

module JekyllBaserowHeadlessCMS
  # Module for organizing Baserow data into different structures
  module DataOrganizers
    module_function

    # Organize data based on the specified organizer type
    # @param baserow_data [Hash] Raw data from the Baserow API (rows under 'results')
    # @param config [Hash] Collection configuration
    # @return [Hash, Array] Organized data
    def organize(baserow_data, config)
      organizer = config['organizer'] || 'simple_list'
      fields_config = config['fields'] || []
      sort_by = config['sort_by']
      sort_order = config['sort_order'] || 'asc'

      case organizer
      when 'simple_list'
        organize_simple_list(baserow_data, fields_config, sort_by, sort_order)
      when 'items_by_category'
        organize_items_by_category(baserow_data, fields_config)
      when 'grouped_by'
        group_field = config['group_by']
        organize_grouped_by(baserow_data, fields_config, group_field, sort_by, sort_order)
      when 'nested'
        parent_field = config['parent_field'] || 'parent_id'
        organize_nested(baserow_data, fields_config, parent_field, sort_by, sort_order)
      else
        organize_simple_list(baserow_data, fields_config, sort_by, sort_order)
      end
    end

    # Organize as a simple sorted list
    # @param baserow_data [Hash] Raw data from the Baserow API
    # @param fields_config [Array<Hash>] Field configuration
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order ('asc' or 'desc')
    # @return [Array<Hash>] Sorted list of items
    def organize_simple_list(baserow_data, fields_config, sort_by, sort_order)
      items = baserow_data['results'].map do |row|
        item = FieldExtractors.extract_all(row, fields_config)
        item['id'] = row['id']
        item
      end

      # Filter out items without title
      items = items.select { |item| item['title'] && !item['title'].to_s.empty? }

      # Sort if sort_by is specified
      sort_items(items, sort_by, sort_order)
    end

    # Organize items grouped by category
    # Useful for skills, products, team members, or any items with category grouping
    # @param baserow_data [Hash] Raw data from the Baserow API
    # @param fields_config [Array<Hash>] Field configuration
    # @return [Hash] Items grouped by category
    def organize_items_by_category(baserow_data, _fields_config)
      items_by_category = {}

      baserow_data['results'].each do |row|
        process_category_row(row, items_by_category)
      end

      sort_categories_and_items(items_by_category)
    end

    # Process a single row for category organization
    def process_category_row(row, items_by_category)
      name = FieldExtractors.extract(row, 'Name', 'text')
      return if name.nil? || name.empty?

      category_data = extract_category_data(row)
      category_name = category_data[:name]

      items_by_category[category_name] ||= build_category_hash(category_data)
      items_by_category[category_name]['items'] << build_category_item(row, name, category_data)
    end

    # Extract category-related data from a row (via lookup fields, Baserow's rollup equivalent)
    def extract_category_data(row)
      {
        name: FieldExtractors.extract(row, 'Category', 'lookup') || 'Other',
        icon: FieldExtractors.extract(row, 'Icon', 'lookup'),
        color: FieldExtractors.extract(row, 'Color', 'lookup'),
        order: FieldExtractors.extract(row, 'Category Order', 'lookup')
      }
    end

    # Build the category hash structure
    def build_category_hash(category_data)
      order = category_data[:order]
      {
        'title' => category_data[:name],
        'category' => category_data[:name],
        'subcategory' => nil,
        'icon' => category_data[:icon],
        'order' => (order.is_a?(Array) ? order.first : order) || 999,
        'items' => []
      }
    end

    # Build an item hash for category organization
    def build_category_item(row, name, category_data)
      {
        'name' => name,
        'level' => FieldExtractors.extract(row, 'Level', 'number'),
        'years' => FieldExtractors.extract(row, 'Years', 'number'),
        'description' => nil,
        'icon' => nil,
        'color' => category_data[:color],
        'featured' => FieldExtractors.extract(row, 'Featured', 'boolean'),
        'order' => FieldExtractors.extract(row, 'Order', 'number') || 999,
        'id' => row['id']
      }
    end

    # Sort categories and their items
    def sort_categories_and_items(items_by_category)
      sorted = items_by_category.sort_by do |_, data|
        order = data['order']
        (order.is_a?(Array) ? order.first : order).to_i
      end.to_h

      sorted.each_value do |data|
        data['items'].sort_by! { |item| item['order'].to_i }
      end

      sorted
    end

    # Organize items grouped by a field
    # @param baserow_data [Hash] Raw data from the Baserow API
    # @param fields_config [Array<Hash>] Field configuration
    # @param group_field [String] Field to group by
    # @param sort_by [String] Field to sort by within groups
    # @param sort_order [String] Sort order
    # @return [Hash] Items grouped by field
    def organize_grouped_by(baserow_data, fields_config, group_field, sort_by, sort_order)
      grouped = {}

      baserow_data['results'].each do |row|
        item = FieldExtractors.extract_all(row, fields_config)
        item['id'] = row['id']

        next if item['title'].nil? || item['title'].to_s.empty?

        group_key = item[group_field]
        group_key = group_key.first if group_key.is_a?(Array)
        group_key ||= 'Other'

        grouped[group_key] ||= []
        grouped[group_key] << item
      end

      # Sort within groups
      grouped.each_value do |items|
        sort_items(items, sort_by, sort_order)
      end

      grouped
    end

    # Organize items in a nested tree structure
    # @param baserow_data [Hash] Raw data from the Baserow API
    # @param fields_config [Array<Hash>] Field configuration
    # @param parent_field [String] Field containing parent reference
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order
    # @return [Array<Hash>] Nested tree of items
    def organize_nested(baserow_data, fields_config, parent_field, sort_by, sort_order)
      items = {}
      roots = []

      # First pass: extract all items
      baserow_data['results'].each do |row|
        item = FieldExtractors.extract_all(row, fields_config)
        item['id'] = row['id']
        item['children'] = []
        items[row['id']] = item
      end

      # Second pass: build tree structure
      items.each_value do |item|
        parent_ids = item[parent_field]
        parent_id = parent_ids.is_a?(Array) ? parent_ids.first : parent_ids

        if parent_id && items[parent_id]
          items[parent_id]['children'] << item
        else
          roots << item
        end
      end

      # Sort at each level
      sort_nested(roots, sort_by, sort_order)

      roots
    end

    # Sort items by field
    # @param items [Array<Hash>] Items to sort
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order ('asc' or 'desc')
    # @return [Array<Hash>] Sorted items
    def sort_items(items, sort_by, sort_order)
      return items unless sort_by && !sort_by.empty?

      items.sort_by! do |item|
        value = item[sort_by]
        case value
        when nil then sort_order == 'desc' ? -Float::INFINITY : Float::INFINITY
        when Numeric then value
        when String then value.downcase
        else value.to_s.downcase
        end
      end

      items.reverse! if sort_order == 'desc'
      items
    end

    # Recursively sort nested items
    # @param items [Array<Hash>] Items to sort
    # @param sort_by [String] Field to sort by
    # @param sort_order [String] Sort order
    def sort_nested(items, sort_by, sort_order)
      sort_items(items, sort_by, sort_order)

      items.each do |item|
        sort_nested(item['children'], sort_by, sort_order) if item['children']&.any?
      end
    end

    # Check if data is present (non-empty)
    # @param data [Hash, Array] Data to check
    # @return [Boolean] True if data is present
    def data_present?(data)
      return false if data.nil?

      if data.is_a?(Hash)
        data.size.positive?
      else
        data.length.positive?
      end
    end
  end
end
