# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-19

### Added

- Initial release of jekyll-baserow-headless-cms, adapted from
  [jekyll-notion-cms](https://github.com/maxime-lenne/jekyll-notion-cms) to use
  [Baserow](https://baserow.io) as the content source instead of Notion
- Configurable collections via `_config.yml`
- Support for Baserow field types:
  - Text, Long text, Number, Boolean
  - Date, Created on, Last modified
  - Single select, Multiple select
  - URL, Email, Phone number
  - File, Rating, Count
  - Link to table, Lookup, Formula
- Multiple data organizers:
  - `simple_list` - Sorted array of items
  - `items_by_category` - Items grouped by category (skills, products, etc.)
  - `grouped_by` - Items grouped by a field
  - `nested` - Hierarchical tree structure
- Automatic fallback to Jekyll collections
- Pagination support for large tables
- Data file caching to avoid unnecessary regeneration
- Comprehensive logging
- Support for self-hosted Baserow instances via `BASEROW_API_URL`

### Security

- Secure handling of Baserow API tokens via environment variables

[0.1.0]: https://github.com/maxime-lenne/jekyll-baserow-headless-cms/releases/tag/v0.1.0
