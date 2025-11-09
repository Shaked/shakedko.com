# shakedko.com

Personal blog hosted on GitHub Pages with Jekyll.

## Structure

This repository contains a complete GitHub Pages structure using Jekyll:

- **_config.yml** - Jekyll configuration file
- **_posts/** - Directory for blog posts (use format: YYYY-MM-DD-title.md)
- **_layouts/** - HTML templates for pages
  - default.html - Main page layout
  - post.html - Blog post layout
- **_includes/** - Reusable HTML components
  - header.html - Site header with navigation
  - footer.html - Site footer
- **assets/css/** - Stylesheets
  - style.scss - Custom CSS styles
- **index.html** - Homepage that lists blog posts
- **about.md** - About page
- **Gemfile** - Ruby dependencies for local development

## Getting Started

### Viewing on GitHub Pages

Once this is merged to the main branch and GitHub Pages is enabled in repository settings, the site will be available at https://shakedko.com

### Local Development

To run locally:

1. Install Ruby and Bundler
2. Run `bundle install` to install dependencies
3. Run `bundle exec jekyll serve` to start the local server
4. Visit http://localhost:4000 in your browser

## Creating New Blog Posts

1. Create a new file in `_posts/` with the format: `YYYY-MM-DD-title.md`
2. Add front matter at the top:
   ```yaml
   ---
   layout: post
   title: "Your Post Title"
   date: YYYY-MM-DD HH:MM:SS -0500
   categories: category1 category2
   tags: [tag1, tag2]
   ---
   ```
3. Write your content in Markdown below the front matter
4. Commit and push to publish

## Redirecting Old URLs

If you're migrating content from an old blog and want to preserve old URLs, you can use the `redirect_from` feature:

1. Add a `redirect_from` field to your post's front matter with a list of old URLs:
   ```yaml
   ---
   layout: post
   title: "Your Post Title"
   date: 2013-11-23 10:00:00 -0500
   redirect_from:
     - /2013/Nov/23/old-url.html
     - /old-blog/2013/old-url.html
   ---
   ```

2. The `jekyll-redirect-from` plugin will automatically create HTML files at those old URLs that redirect to your new post URL.

3. Example: A post created as `_posts/2013-11-23-tinder-privacy-issues.md` will be available at `/2013/11/23/tinder-privacy-issues/`, but can also redirect from `/2013/Nov/23/tinder-privacy-issues.html` by adding it to `redirect_from`.

See `_posts/2013-11-23-tinder-privacy-issues.md` for a working example.

## Example Blog Post

An example blog post has been created at `_posts/2025-11-09-welcome-to-my-blog.md` demonstrating the structure and Markdown features. You can replace or delete this when you're ready.
