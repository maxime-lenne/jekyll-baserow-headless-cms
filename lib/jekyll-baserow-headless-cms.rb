# frozen_string_literal: true

require 'jekyll'
require_relative 'jekyll_baserow_headless_cms/version'
require_relative 'jekyll_baserow_headless_cms/baserow_client'
require_relative 'jekyll_baserow_headless_cms/field_extractors'
require_relative 'jekyll_baserow_headless_cms/data_organizers'
require_relative 'jekyll_baserow_headless_cms/generator'

module JekyllBaserowHeadlessCMS
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class APIError < Error; end
end
