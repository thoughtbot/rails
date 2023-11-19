**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON https://guides.rubyonrails.org.**

Building Accessible Experiences in Rails Applications
=====================================================

[WAI-ARIA Overview](https://www.w3.org/WAI/standards-guidelines/aria/)
[Accessibility Fundamentals Overview](https://www.w3.org/WAI/fundamentals/)
[Accessibility Principles](https://www.w3.org/WAI/fundamentals/accessibility-principles/)
[ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/)

NOTE: Creating accessible experiences requires more than "correct" HTML attributes and text content.

Broad planning, prioritizing and designing for keyboard-only experiences, familiarity with the assistive
technology ecosystem (like screen readers), etc.

For the parts that do, Action View provides tools for rendering HTML with the necessary attributes and text content.

## Utilities

### ARIA Attribute Options

Prefer semantically meaningful HTML elements and attributes

When resorting to ARIA, use `aria: {}` in the same way as `data: {}`:

```ruby
link_to "Articles", "/articles", "aria-current": "page" }
# => <a href="/articles" aria-current="page">Articles</a>

link_to "Articles", "/articles", aria: { current: "page" }
# => <a href="/articles" aria-current="page">Articles</a>
```

### Styles

Elements must have sufficient color contrast
Interactive elements must have focus styles
etc.

In addition to classes that match those guidelines, a class to "visually" hide
elements while still communicating their contents to assistive technologies can
be useful.

* Bootstrap includes [.visually-hidden](https://getbootstrap.com/docs/5.3/helpers/visually-hidden/) CSS class
* Tailwind includes [.sr-only](https://tailwindcss.com/docs/screen-readers) CSS class

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```

* Include visual styles for pseudo-states (for example, `:focus` instead of a
  CSS class)

```css
button {
  color: black;
}

button:disabled {
  color: gray;
}
```

```css
button:focus {
  outline-style: solid;
  /** other focus styles */
}
```

Similar styles should be applied to interactive elements that can be "selected"
without receiving focus. For example, elements rendered with `[role="option"]` that are nested within a `[role="listbox"]` element and controlled by a `[role="combobox"]` element:

```css
button:focus,
[role="option"][aria-selected="true"],
  outline-style: solid;
  /** other focus styles */
}
```

* Incorporate element-specific and ARIA state into styles (for example,
  `[aria-current="page"]` instead of CSS class)

## Document Language

When the application language is known, set the
[lang](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/lang#accessibility_concerns)
attribute on the `<html>` element.

## Landmark Regions

Prefer semantically meaningful HTML elements, like [landmark regions](https://www.w3.org/WAI/ARIA/apg/practices/landmark-regions/)

### Top Level Landmarks

```html+erb
<%# app/views/layouts/application.html.erb %>

<html>
  <head>
    <%# ... %>
  </head>
  <body>
    <% if content_for? :header %>
    <header>
      <%= yield :header %>
    </header>
    <% end %>

    <main>
      <%= yield %>
    </main>

    <% if content_for? :footer %>
    <footer>
      <%= yield :footer %>
    </footer>
    <% end %>
  </body>
</html>
```

### Sectioning Elements

References between `[id]` and `[aria-labelledby]`

```html+erb
<section aria-labelledby="section_title">
  <h2 id="section_title">Region label</h2>
</section>
```

When dynamic values are required, use [`dom_id`](https://api.rubyonrails.org/classes/ActionView/RecordIdentifier.html#method-i-dom_id):

```html+erb
<section aria-labelledby="<%= dom_id(@article, "title") %>">
  <h2 id="<%= dom_id(@article, "title") %>">
    <%= @article.title %>
  </h2>
</section>
```

Pass ARIA attributes nested in objects passed as the `aria:` keyword argument:

```html+erb
<%= content_tag :section, aria: { labelledby: dom_id(@article, "title") } do %>
  <%= content_tag :h1, @article.title, id: dom_id(@article, "title") %>
<% end %>
```

Prefer using visible text content when possible. In circumstances where you
cannot, use `[aria-label]`:

```html+erb
<%= content_tag :section, aria: { label: @article.title } do %>
  <%= content_tag :h1, @article.title %>
<% end %>
```

[Use mark-up to convey meaning and structure](https://www.w3.org/WAI/tips/developing/#use-mark-up-to-convey-meaning-and-structure)

## Form Controls

Fields must have visible label text

Derived from the contents of a `<label>` element

```html+erb
<%= form_with model: @article do |form| %>
  <%= form.label :title %>      <%# => <label for="article_title">Title</label> %>
  <%= form.text_field :title %> <%# => <input id="article_title" name="article[title]" type="text"> %>
<% end %>
```

Derived from an `[aria-label]` attribute

```html+erb
<%= form_with model: @article do |form| %>
  <%= form.text_field :title, aria: { label: "Title" } %>
  <%# => <input id="article_title" name="article[title]" aria-label="Title"> %>
<% end %>
```

radio and checkbox inside `<fieldset>` + `<legend>`

```html+erb
<%= form_with model: @article do |form| %>
  <%= field_set_tag "Categories" do %>
    <%= form.collection_check_boxes :categories_ids, Category.all, :id, :name %>
  <% end %>
<% end %>
```

## System Tests

Actions

* fill forms based on accessible names (label text, `aria-label`, or `aria-labelledby`). Do not use `[id]`, `[name]`, or `[placeholder]`
* `click_link` and `click_button` over `click_on`
* drive with mouse clicks
* drive with tab navigation to move focus, keyboard to interact

Assertions

* scope assertions within landmarks

```ruby
# Discouraged: asserts links anywhere on the page
assert_link "Home", href: root_path
assert_link "Sign in", href: new_session_path
assert_link "About us", href: about_us_path
assert_link "Terms", href: terms_path

# Encouraged: asserts links in banner landmark
within :element, role: "banner", aria: { label: "Header" } do
  assert_link "Home", href: root_path
  assert_link "Sign in", href: new_session_path
end

# Encouraged: asserts links in contentinfo landmark
within :element, role: "contentinfo", aria: { label: "Footer" } do
  assert_link "About us", href: about_us_path
  assert_link "Terms", href: terms_path
end
```

```ruby
# <table>
#   <caption>Users</caption>
#   <tr>
#     <th>Email address</th>
#     <th>Name</th>
#   </tr>
#   <tr>
#     <td>user1@example.com</td>
#     <td>User #1</td>
#   </tr>
#   <tr>
#     <td>user2@example.com</td>
#     <td>User #2</td>
#   </tr>
# </table>

# Discouraged: asserts text without scoping
assert_text "user1@example.com"
assert_text "User #1"
assert_text "user2@example.com"
assert_text "User #2"

# Encouraged: asserts text scoped to rows within a table resolved by caption text
assert_table "Users", with_rows: [
  { "Email address" => "user1@example.com", "Name" => "User #1" },
  { "Email address" => "user2@example.com", "Name" => "User #2" },
]

# Encouraged: asserts rows scoped to table resolved by caption text
within_table "Users" do
  assert_selector :table_row, "Email address" => "user1@example.com", "Name" => "User #1"
  assert_selector :table_row, "Email address" => "user2@example.com", "Name" => "User #2"
end
```

* assert using accessible names and [built-in Capybara Selectors](https://rubydoc.info/github/teamcapybara/capybara/master/Capybara/Selector#built-in-selectors)

```ruby
# <label for="article_name">Name</label>
# <input id="article_name" name="article[name]" value="Hello, world">

# Discouraged: asserts [id] attribute value
assert_field "article_name", with: "Hello, world"
# Discouraged: asserts [name] attribute value
assert_field "article[name]", with: "Hello, world"
# Encouraged: asserts accessible name inferred from label text
assert_field "Name", with: "Hello, world"
```

```ruby
# <button>Submit</button>

# Discouraged: asserts with CSS selector and text filter
assert_css "button", text: "Submit"
# Encouraged: asserts with Capybara selector and locator
assert_button "Submit"
```

* assert user-facing state (`[disabled]`, `:focus`, `[aria-*]` state, etc)

```ruby
# <a href="/get_started" autofocus>Get Started</a>

# Discouraged: asserts with CSS attribute and pseudo-class selectors and text: filter
assert_css "a[autofocus]:focus", text: "Get Started"
# Encouraged: asserts with Capybara selector, locator, and focused: filter
assert_link "Submit", focused: true
```

## Integration Tests

Requires parsing HTML responses into Nokogiri nodes, then wrapping those with Capybara

While it's important for an application's System Test suite to faithfully
recreate end-user in-browser experiences, its Integration Tests are free to
focus on the implementation details of how its server generates HTML responses.

For example, assertions that resolve form controls by their `[id]`, `[name]`, or
`[placeholder]` attributes are discouraged in System Tests. In Integration
Tests, assertions about those attributes and others like them are encouraged.

```ruby
# <label for="article_name">Name</label>
# <input id="article_name" name="article[name]" value="Hello, world">

# Discouraged: asserts with accessible name only
assert_field "Name"
# Encouraged: asserts with accessible name and other HTML attributes
assert_field "Name", type: "text", name: "article[name]", with: "Hello, world"
```

* see [System Tests](#system-tests), but don't use any Actions (like
  `visit`, `click_link`, `fill_in`, etc.
* are purely HTML, so ignore any CSS rules applied through `[class]` or `[style]` attributes
    * able to determine visibility with `[hidden]` attribute
    * ignores any `display: none;`

## View Tests

Requires parsing HTML fragments into Nokogiri nodes, then wrapping those with Capybara

While it's important for an application's System Test suite to faithfully
recreate end-user in-browser experiences, its View Tests are free to
focus on the implementation details of how its server generates HTML fragments.

For example, assertions that resolve form controls by their `[id]`, `[name]`, or
`[placeholder]` attributes are discouraged in System Tests. In View Tests,
assertions about those attributes and others like them are encouraged.

* see [Integration Tests](#integration-tests)
