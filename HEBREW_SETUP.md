# Hebrew Posts Setup

## Overview

The blog now supports Hebrew posts in a separate section that:
- Lives in the `_posts_he/` directory
- Has its own page at `/he/`
- Uses RTL (right-to-left) layout
- Does NOT appear on the main English page
- Supports pinned posts (same as English)

## Accessing Hebrew Posts

### Primary URL
```
https://shakedko.com/he
```

### Subdomain (requires DNS setup)
```
https://he.shakedko.com
```

## Adding Hebrew Posts

1. Create a new markdown file in `_posts_he/` directory:
   ```
   _posts_he/2024-01-15-example-hebrew-post.md
   ```

2. Use this front matter template:
   ```yaml
   ---
   layout: post
   title: "כותרת הפוסט בעברית"
   date: 2024-01-15 10:00:00 -0500
   categories: קטגוריה
   tags: [תג1, תג2]
   author: Shaked Klein Orbach
   lang: he
   ---
   ```

3. Write your content in Hebrew below the front matter

## Pinning Hebrew Posts

Add `pinned: true` to the front matter:
```yaml
---
layout: post
title: "פוסט נעוץ"
date: 2024-01-15 10:00:00 -0500
pinned: true
lang: he
---
```

## Setting up he.shakedko.com Subdomain

### GitHub Pages Configuration

1. Add DNS records at your domain registrar:
   ```
   Type: CNAME
   Name: he
   Value: shakedko.com
   ```

2. In GitHub repository settings:
   - Go to Settings → Pages
   - Under "Custom domain", the main domain should already be `shakedko.com`
   - The subdomain will work automatically once DNS propagates

### Alternative: Add to CNAME file

If you want explicit subdomain support, create/update `CNAME` file:
```
shakedko.com
he.shakedko.com
```

**Note**: GitHub Pages typically only allows one custom domain per repository. The subdomain routing works through the `/he/` path and DNS CNAME record pointing to the main domain.

## Features

### Language Switcher
- English pages show: 🇮🇱 עברית link
- Hebrew pages show: 🇺🇸 English link
- Located in header navigation and at bottom of post lists

### RTL Support
- Hebrew pages automatically use `dir="rtl"`
- Posts display right-to-left
- Layout adjusts for Hebrew text

### Separate Collections
- English: `site.posts` collection
- Hebrew: `site.posts_he` collection
- Each maintains its own chronological order
- Pinned posts work independently in each language

## Existing Hebrew Posts

Two Hebrew posts have been migrated from the old blog:

1. **מעצמת הסייבר וקופות החולים** (2018-10-29)
   - URL: `/he/2018/10/29/מעצמת-הסייבר-וקופות-החולים/`
   - Redirects from old URLs including URL-encoded version

2. **תוהים אם זו טעות** (2018-11-20)
   - URL: `/he/2018/11/20/תוהים-אם-זו-טעות/`
   - Redirects from old URLs including URL-encoded version

Both posts include:
- Twitter embed support using `{% include twitter-embed.html %}`
- Images from `/assets/images/`
- Proper RTL layout
- Full redirect support from old blog URLs

## URL Structure

### English Posts
```
https://shakedko.com/2024/01/15/post-title/
```

### Hebrew Posts
```
https://shakedko.com/he/2024/01/15/post-title/
https://he.shakedko.com/2024/01/15/post-title/ (with DNS setup)
```

## Testing Locally

Run the development server:
```bash
make serve
```

Then access:
- English: http://localhost:4000
- Hebrew: http://localhost:4000/he

