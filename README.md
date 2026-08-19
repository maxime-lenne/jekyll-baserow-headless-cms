# Jekyll Baserow Headless CMS

<p align="center">
  <img src="https://cdn.simpleicons.org/baserow" alt="Baserow" width="80" height="80" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/jekyll/jekyll-original.svg" alt="Jekyll" width="80" height="80" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/githubactions/githubactions-original-wordmark.svg" alt="Github Action" width="80" height="80" />
</p>

<p align="center">
  <strong>Use Baserow as a headless CMS for your Jekyll static site</strong>
</p>

<p align="center">
  <a href="https://badge.fury.io/rb/jekyll-baserow-headless-cms"><img src="https://badge.fury.io/rb/jekyll-baserow-headless-cms.svg" alt="Gem Version" /></a>
  <a href="https://github.com/maxime-lenne/jekyll-baserow-headless-cms/actions/workflows/ci.yml"><img src="https://github.com/maxime-lenne/jekyll-baserow-headless-cms/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT" /></a>
</p>

---

A configurable Jekyll plugin that fetches content from [Baserow](https://baserow.io) tables and makes it available as Jekyll data files. Perfect for building landing pages, portfolios, blogs, and resumes with Baserow as your content management system.

This project is a Baserow-flavored sibling of [jekyll-notion-cms](https://github.com/maxime-lenne/jekyll-notion-cms) — same architecture and organizer system, adapted for Baserow's REST API and field model.

## Features

- **Configurable Collections**: Define any number of Baserow table collections via `_config.yml`
- **Multiple Organizers**: Support for different data organization patterns (simple list, grouped, skills by category, nested)
- **Common Field Types**: Support for the main Baserow field types (text, number, date, select, multi-select, link to table, lookups, files, etc.)
- **Fallback System**: Automatic fallback to Jekyll collections when Baserow is unavailable
- **Pagination**: Handles large tables with automatic pagination
- **Caching**: Intelligent file caching to avoid unnecessary regenerations
- **Self-hosted friendly**: Works with baserow.io or any self-hosted Baserow instance via `BASEROW_API_URL`

## Use Cases

### Landing Page

Build dynamic landing pages with content managed entirely in Baserow:

| Content Type | Baserow Table | Description |
|--------------|----------------|--------------|
| **Services** | Services | List your offerings with icons, descriptions, and pricing |
| **Testimonials** | Testimonials | Client reviews with photos, quotes, and ratings |
| **Team** | Team | Team member profiles with photos and bios |
| **FAQ** | FAQ | Frequently asked questions organized by category |

### Portfolio

Showcase your work with a portfolio powered by Baserow:

| Content Type | Baserow Table | Description |
|--------------|----------------|--------------|
| **Projects** | Projects | Portfolio pieces with images, descriptions, and links |
| **Skills** | Skills | Technical skills organized by category with proficiency levels |
| **Certifications** | Certifications | Professional certifications and badges |

### Blog

Run a full-featured blog with Baserow as your writing tool:

| Content Type | Baserow Table | Description |
|--------------|----------------|--------------|
| **Posts** | Blog | Articles with rich text, tags, and publication dates |
| **Categories** | Categories | Blog categories for organization |
| **Authors** | Authors | Author profiles for multi-author blogs |

### Resume / CV

Create a dynamic online resume:

| Content Type | Baserow Table | Description |
|--------------|----------------|--------------|
| **Experiences** | Experiences | Work history with dates, companies, and descriptions |
| **Education** | Education | Academic background and degrees |
| **Skills** | Skills | Technical and soft skills with proficiency |
| **Languages** | Languages | Language proficiencies |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jekyll-baserow-headless-cms'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install jekyll-baserow-headless-cms
```

## Quick Start

### 1. Create a Baserow API token

1. Go to your Baserow workspace settings
2. Create a new **Database token** scoped to the workspace/database you want to sync
3. Copy the token

### 2. Configure Environment Variables

```bash
export BASEROW_TOKEN=your_database_token
export BASEROW_EXPERIENCES_TABLE=your_table_id
export BASEROW_BLOG_TABLE=your_blog_table_id

# Optional: only needed for a self-hosted Baserow instance
export BASEROW_API_URL=https://baserow.example.com
```

### 3. Add Configuration to `_config.yml`

```yaml
baserow:
  enabled: true

  collections:
    experiences:
      table_env: BASEROW_EXPERIENCES_TABLE
      data_file: baserow_experiences.yml
      organizer: simple_list
      sort_by: order
      fields:
        - { name: Title, type: text }
        - { name: Company, type: text }
        - { name: Start Date, type: date, key: start_date }
        - { name: Current, type: boolean }
        - { name: Tags, type: multi_select }

    blog_posts:
      table_env: BASEROW_BLOG_TABLE
      data_file: baserow_blog_posts.yml
      organizer: simple_list
      sort_by: published_at
      sort_order: desc
      fields:
        - { name: Title, type: text }
        - { name: Slug, type: text }
        - { name: Language, type: single_select }
        - { name: Published At, type: date, key: published_at }
        - { name: Status, type: single_select }
        - { name: Excerpt, type: long_text }
        - { name: Tags, type: multi_select }
```

### 4. Use Data in Templates

```liquid
{% for exp in site.data.baserow_experiences %}
  <h3>{{ exp.title }}</h3>
  <p>{{ exp.company }} - {{ exp.start_date }}</p>
{% endfor %}
```

## Examples & Configuration

For detailed examples and configuration reference, see **[Examples & Configuration](docs/EXAMPLES_AND_CONFIGURATION.md)**.

**Examples included:**
- Projects Table (portfolio, case studies)
- Services Table (freelancers, agencies)
- Testimonials Table (client reviews)
- Skills Table (technical expertise)

**Configuration reference:**
- Collection options
- Organizer types (`simple_list`, `items_by_category`, `grouped_by`, `nested`)
- Supported field types
- Field configuration syntax

## Fallback System

When Baserow is unavailable, the plugin automatically falls back to Jekyll collections:

1. **No `BASEROW_TOKEN`**: Uses all Jekyll collections
2. **Missing table ID**: Uses fallback for that collection
3. **API Error**: Falls back gracefully with error logging

Create fallback collections in `_collections/`:

```
_collections/
├── _experiences/
│   ├── experience-1.md
│   └── experience-2.md
└── _blog_posts/
    └── my-post.md
```

## Automation & Deployment

### GitHub Actions Workflow

Copy the workflow template to your repository:

```bash
cp docs/templates/github-actions_baserow-sync.yml .github/workflows/baserow-sync.yml
```

**Full workflow file:** [`docs/templates/github-actions_baserow-sync.yml`](docs/templates/github-actions_baserow-sync.yml)

### Automatic Sync with Baserow Webhooks

Unlike Notion, Baserow tables support **native webhooks** with custom HTTP headers, so they
can call the GitHub REST API directly — no relay or serverless function needed:

1. **Create a GitHub Personal Access Token** (fine-grained, scoped to this repo) with the
   **Actions: Read and write** permission. This is what lets Baserow trigger the workflow.
2. In Baserow, open your table → **Webhooks** → **Create webhook**:
   - **Events**: `Rows created`, `Rows updated`, `Rows deleted` (pick what you need)
   - **URL**: `https://api.github.com/repos/<owner>/<repo>/actions/workflows/baserow-sync.yml/dispatches`
   - **Method**: `POST`
   - **Headers**:
     - `Authorization: Bearer <your PAT>`
     - `Accept: application/vnd.github+json`
   - **Body** (JSON): `{"ref": "main"}`

   The `baserow_event`/`table_id` inputs in the template have defaults, so a minimal
   `{"ref": "main"}` body is enough — those inputs mainly help distinguish manual/CLI runs.
3. Repeat per table you want to watch (Baserow webhooks are scoped to one table).

Or trigger the workflow manually via GitHub CLI:

```bash
gh workflow run baserow-sync.yml \
  -f baserow_event=manual \
  -f table_id=all
```

Or via the GitHub Actions UI by clicking "Run workflow" on the Actions tab.

## Development

After checking out the repo:

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Run console
bundle exec rake console
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/maxime-lenne/jekyll-baserow-headless-cms.

1. Fork it
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

**Maxime Lenne** - [maxime-lenne.fr](https://maxime-lenne.fr)

- GitHub: [@maxime-lenne](https://github.com/maxime-lenne)
- LinkedIn: [maximelenne](https://linkedin.com/in/maximelenne)
