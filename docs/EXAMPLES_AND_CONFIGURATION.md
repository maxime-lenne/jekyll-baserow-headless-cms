# Examples & Configuration Reference

This document provides detailed examples and configuration reference for jekyll-baserow-headless-cms.

## Table of Contents

- [Examples](#examples)
  - [Projects Table](#projects-table)
  - [Services Table](#services-table)
  - [Testimonials Table](#testimonials-table)
  - [Skills Table](#skills-table)
- [Configuration Reference](#configuration-reference)
  - [Collection Options](#collection-options)
  - [Organizer Types](#organizer-types)
  - [Field Types](#field-types)
  - [Field Configuration](#field-configuration)

---

## Examples

### Projects Table

Perfect for portfolios and case studies.

**Baserow Table Structure:**

| Field | Type | Description |
|-------|------|-------------|
| Name | Single line text | Project name |
| Description | Long text | Project description |
| Image | File | Cover image |
| Tags | Multiple select | Technologies used |
| URL | URL | Live project link |
| GitHub | URL | Repository link |
| Featured | Boolean | Show on homepage |
| Order | Number | Display order |

**Configuration:**

```yaml
baserow:
  collections:
    projects:
      table_env: BASEROW_PROJECTS_TABLE
      data_file: baserow_projects.yml
      organizer: simple_list
      sort_by: order
      fields:
        - { name: Name, type: text }
        - { name: Description, type: long_text }
        - { name: Image, type: file }
        - { name: Tags, type: multi_select }
        - { name: URL, type: url }
        - { name: GitHub, type: url, key: github_url }
        - { name: Featured, type: boolean }
        - { name: Order, type: number }
```

**Template Usage:**

```liquid
{% for project in site.data.baserow_projects %}
  {% if project.featured %}
  <article class="project-card">
    {% if project.image.first %}
      <img src="{{ project.image.first.url }}" alt="{{ project.title }}" />
    {% endif %}
    <h3>{{ project.title }}</h3>
    <p>{{ project.description }}</p>
    <div class="tags">
      {% for tag in project.tags %}
        <span class="tag">{{ tag }}</span>
      {% endfor %}
    </div>
    <div class="links">
      {% if project.url %}<a href="{{ project.url }}">View Project</a>{% endif %}
      {% if project.github_url %}<a href="{{ project.github_url }}">GitHub</a>{% endif %}
    </div>
  </article>
  {% endif %}
{% endfor %}
```

---

### Services Table

Ideal for freelancers and agencies.

**Baserow Table Structure:**

| Field | Type | Description |
|-------|------|-------------|
| Name | Single line text | Service name |
| Description | Long text | Service description |
| Icon | Single select | Icon identifier (e.g., "code", "design") |
| Price | Single line text | Pricing information |
| Features | Long text | Key features (bullet points) |
| Category | Single select | Service category |
| Order | Number | Display order |

**Configuration:**

```yaml
baserow:
  collections:
    services:
      table_env: BASEROW_SERVICES_TABLE
      data_file: baserow_services.yml
      organizer: grouped_by
      group_by: category
      sort_by: order
      fields:
        - { name: Name, type: text }
        - { name: Description, type: long_text }
        - { name: Icon, type: single_select }
        - { name: Price, type: text }
        - { name: Features, type: long_text }
        - { name: Category, type: single_select }
        - { name: Order, type: number }
```

**Template Usage:**

```liquid
{% for category in site.data.baserow_services %}
  <section class="service-category">
    <h2>{{ category[0] }}</h2>
    {% for service in category[1] %}
      <div class="service-card">
        <i class="icon-{{ service.icon }}"></i>
        <h3>{{ service.title }}</h3>
        <p>{{ service.description }}</p>
        <p class="price">{{ service.price }}</p>
      </div>
    {% endfor %}
  </section>
{% endfor %}
```

---

### Testimonials Table

Build trust with client testimonials.

**Baserow Table Structure:**

| Field | Type | Description |
|-------|------|-------------|
| Quote | Single line text | Testimonial text |
| Author | Single line text | Client name |
| Role | Single line text | Client's job title |
| Company | Single line text | Client's company |
| Avatar | File | Client photo |
| Rating | Rating | Star rating (1-5) |
| Featured | Boolean | Show on homepage |
| Date | Date | Testimonial date |

**Configuration:**

```yaml
baserow:
  collections:
    testimonials:
      table_env: BASEROW_TESTIMONIALS_TABLE
      data_file: baserow_testimonials.yml
      organizer: simple_list
      sort_by: date
      sort_order: desc
      fields:
        - { name: Quote, type: text }
        - { name: Author, type: text }
        - { name: Role, type: text }
        - { name: Company, type: text }
        - { name: Avatar, type: file }
        - { name: Rating, type: rating }
        - { name: Featured, type: boolean }
        - { name: Date, type: date }
```

**Template Usage:**

```liquid
<section class="testimonials">
  {% for testimonial in site.data.baserow_testimonials %}
    {% if testimonial.featured %}
    <blockquote class="testimonial">
      <div class="stars">
        {% for i in (1..testimonial.rating) %}
          <span class="star">★</span>
        {% endfor %}
      </div>
      <p>"{{ testimonial.quote }}"</p>
      <footer>
        {% if testimonial.avatar.first %}
          <img src="{{ testimonial.avatar.first.url }}" alt="{{ testimonial.author }}" class="avatar" />
        {% endif %}
        <cite>
          <strong>{{ testimonial.author }}</strong>
          <span>{{ testimonial.role }}, {{ testimonial.company }}</span>
        </cite>
      </footer>
    </blockquote>
    {% endif %}
  {% endfor %}
</section>
```

---

### Skills Table

Showcase your technical expertise.

For grouping skills by category, model it in Baserow with two tables: a **Skills** table
linked to a **Categories** table (via a *Link to table* field), and a **lookup** field on
Skills that pulls in the category's name (and, optionally, its icon/color/order). This
mirrors how the `items_by_category` organizer worked with Notion rollups.

**Baserow Table Structure (Skills):**

| Field | Type | Description |
|-------|------|-------------|
| Name | Single line text | Skill name |
| Category | Lookup (via link to Categories) | Skill category (Backend, Frontend, etc.) |
| Category Order | Lookup (via link to Categories) | Display order of the category |
| Level | Number | Proficiency level |
| Years | Number | Years of experience |
| Order | Number | Display order within category |

**Configuration:**

```yaml
baserow:
  collections:
    skills:
      table_env: BASEROW_SKILLS_TABLE
      data_file: baserow_skills.yml
      organizer: items_by_category
```

> `items_by_category` reads the `Name`, `Category`, `Icon`, `Color`, `Category Order`,
> `Level`, `Years`, `Featured` and `Order` fields directly from the row — make sure your
> Skills table uses those exact field names (see [Data Organizers](#organizer-types)).

**Template Usage:**

```liquid
{% for category in site.data.baserow_skills %}
  <section class="skill-category">
    <h3>
      <i class="{{ category[1].icon }}"></i>
      {{ category[1].title }}
    </h3>
    <div class="skills-grid">
      {% for item in category[1].items %}
        <div class="skill">
          <span class="skill-name">{{ item.name }}</span>
          <div class="skill-bar">
            <div class="skill-level" style="width: {{ item.level }}%"></div>
          </div>
          <span class="skill-years">{{ item.years }} years</span>
        </div>
      {% endfor %}
    </div>
  </section>
{% endfor %}
```

---

## Configuration Reference

### Collection Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `table_env` | String | Yes | Environment variable containing the Baserow table ID |
| `data_file` | String | Yes | Output filename in `_data/` directory |
| `organizer` | String | No | Data organization method (default: `simple_list`) |
| `sort_by` | String | No | Field key to sort by |
| `sort_order` | String | No | `asc` (default) or `desc` |
| `group_by` | String | No | Field to group by (for `grouped_by` organizer) |
| `fields` | Array | Yes* | Field mapping configuration (*not used by `items_by_category`, which reads fixed field names) |

### Organizer Types

#### `simple_list` (default)

Returns an array of items sorted by the specified field.

```yaml
organizer: simple_list
sort_by: order
sort_order: asc
```

#### `items_by_category`

Groups items by their category. Useful for skills, products, team members, or any categorized content.

```yaml
organizer: items_by_category
```

Output structure:
```yaml
Backend:
  title: Backend
  icon: code
  order: 1
  items:
    - name: Ruby
      level: 90
      years: 10
```

#### `grouped_by`

Groups items by a specified field.

```yaml
organizer: grouped_by
group_by: category
sort_by: order
```

#### `nested`

Creates a hierarchical tree structure based on parent-child relationships.

```yaml
organizer: nested
parent_field: parent_id
sort_by: order
```

### Field Types

| Type | Baserow Field | Output |
|------|-----------------|--------|
| `text` | Single line text | String |
| `long_text` | Long text | String |
| `number` | Number | Integer/Float |
| `boolean` | Boolean | Boolean |
| `date` | Date | ISO 8601 string |
| `single_select` | Single select | String |
| `multi_select` | Multiple select | Array of strings |
| `url` | URL | String |
| `email` | Email | String |
| `phone_number` | Phone number | String |
| `file` | File | Array of file objects |
| `rating` | Rating | Integer |
| `count` | Count | Integer |
| `link_row` | Link to table | Array of `{ id, name }` objects |
| `lookup` | Lookup | Single value or array from a linked table |
| `formula` | Formula (scalar) | Computed value |
| `formula_array` | Formula (array of) | Single value or array of values |
| `created_on` | Created on | ISO 8601 string |
| `last_modified` | Last modified | ISO 8601 string |

### Field Configuration

```yaml
fields:
  - name: "Field Name"       # Name in Baserow (required)
    type: text                # Field type (required)
    key: custom_key           # Output key (optional, defaults to snake_case)
```
