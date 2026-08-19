# frozen_string_literal: true

module JekyllBaserowHeadlessCMS
  # Module for extracting values from Baserow field types
  #
  # Unlike Notion, Baserow returns row data as a flat hash (with
  # `user_field_names=true`) where each key is already the field's value in
  # its natural JSON shape. The declared +field_type+ tells us how to
  # interpret that shape.
  module FieldExtractors
    module_function

    # Extract a field value based on its type
    # @param row [Hash] A row hash from the Baserow API
    # @param field_name [String] The name of the field
    # @param field_type [String] The expected type of the field
    # @return [Object] The extracted value
    def extract(row, field_name, field_type)
      return nil unless row.key?(field_name)

      value = row[field_name]

      case field_type
      when 'text', 'long_text'
        extract_text(value)
      when 'number', 'rating', 'count'
        extract_number(value)
      when 'boolean'
        extract_boolean?(value)
      when 'date', 'created_on', 'last_modified'
        extract_date(value)
      when 'single_select'
        extract_single_select(value)
      when 'multi_select'
        extract_multi_select(value)
      when 'url'
        extract_url(value)
      when 'email'
        extract_email(value)
      when 'phone_number'
        extract_phone_number(value)
      when 'link_row'
        extract_link_row(value)
      when 'lookup', 'formula_array'
        extract_lookup(value)
      when 'formula'
        extract_formula(value)
      when 'file'
        extract_file(value)
      end
    end

    # Extract all fields from a Baserow row based on configuration
    # @param row [Hash] A row hash from the Baserow API
    # @param fields_config [Array<Hash>] Configuration for each field
    # @return [Hash] Extracted fields with normalized keys
    def extract_all(row, fields_config)
      item = {}

      fields_config.each do |field_config|
        field_name = field_config['name']
        field_type = field_config['type']
        field_key = field_config['key'] || normalize_key(field_name)

        value = extract(row, field_name, field_type)
        item[field_key] = value
      end

      # Use 'title' as the main identifier, fall back to 'name'
      item['title'] ||= item['name']

      item
    end

    # Normalize a field name to a valid key
    # @param name [String] The field name
    # @return [String] The normalized key
    def normalize_key(name)
      name.downcase.gsub(/\s+/, '_')
    end

    # Text / long text field
    def extract_text(value)
      return nil if value.nil? || value == ''

      value.to_s
    end

    # Number / rating / count field (Baserow may return decimal numbers as strings)
    def extract_number(value)
      return nil if value.nil?

      case value
      when Numeric
        value
      when String
        value.include?('.') ? value.to_f : value.to_i
      end
    end

    # Boolean field
    def extract_boolean?(value)
      value == true
    end

    # Date / created on / last modified field (returned as an ISO 8601 string)
    def extract_date(value)
      return nil if value.nil? || value == ''

      value.to_s
    end

    # Single select field: { "id" => 1, "value" => "Backend", "color" => "blue" }
    def extract_single_select(value)
      return nil unless value.is_a?(Hash)

      value['value']
    end

    # Multiple select field: array of { "id" => .., "value" => .., "color" => .. }
    def extract_multi_select(value)
      return [] unless value.is_a?(Array)

      value.map { |option| option['value'] }.compact
    end

    # URL field
    def extract_url(value)
      return nil if value.nil? || value == ''

      value.to_s
    end

    # Email field
    def extract_email(value)
      return nil if value.nil? || value == ''

      value.to_s
    end

    # Phone number field
    def extract_phone_number(value)
      return nil if value.nil? || value == ''

      value.to_s
    end

    # Link to table field: array of { "id" => .., "value" => .. }
    def extract_link_row(value)
      return [] unless value.is_a?(Array)

      value.map do |linked_row|
        { 'id' => linked_row['id'], 'name' => linked_row['value'] }.compact
      end
    end

    # Lookup field, or a formula field returning an array: array of { "id" => .., "value" => .. }
    # Mirrors Notion rollups: returns a single value if only one, otherwise an array
    def extract_lookup(value)
      return nil unless value.is_a?(Array)

      values = value.map { |item| item.is_a?(Hash) ? item['value'] : item }.compact
      return nil if values.empty?

      values.length == 1 ? values.first : values
    end

    # Formula field returning a scalar value (string, number, boolean or date)
    def extract_formula(value)
      value
    end

    # File field: array of { "url" => .., "name" => .., "mime_type" => .., ... }
    def extract_file(value)
      return [] unless value.is_a?(Array)

      value.map do |file|
        { 'name' => file['name'], 'url' => file['url'], 'type' => file['mime_type'] }.compact
      end
    end
  end
end
