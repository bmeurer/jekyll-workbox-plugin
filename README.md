# Jekyll Workbox Plugin [![Gem Version](https://badge.fury.io/rb/jekyll-workbox-plugin.png)](http://badge.fury.io/rb/jekyll-workbox-plugin)

> Google Workbox integration for Jekyll

This plugin provides integration with [Google Workbox](https://developers.google.com/web/tools/workbox/) for the [Jekyll](https://jekyllrb.com/) static site generator. It generates a service worker and provides precache integration with artifacts managed by Jekyll.

This plugin provides [workbox-cli](https://developers.google.com/web/tools/workbox/modules/workbox-cli) like functionality for projects using Jekyll. It's based on the [Jekyll PWA Plugin](https://github.com/lavas-project/jekyll-pwa), but it tries to be less clever than that, and focuses purely on the Workbox integration.

You see this plugin in action on [my website](https://benediktmeurer.de), which is built using Jekyll and comes with a service worker for offline capabilities.

## Installation

This plugin is available as a [RubyGem][ruby-gem].

### Option #1

Add `gem 'jekyll-workbox-plugin'` to the `jekyll_plugin` group in your `Gemfile`:

```ruby
source 'https://rubygems.org'

gem 'jekyll'

group :jekyll_plugins do
  gem 'jekyll-workbox-plugin'
end
```

Then run `bundle` to install the gem.

### Option #2

Alternatively, you can also manually install the gem using the following command:

```
$ gem install jekyll-workbox-plugin
```

After the plugin has been installed successfully, add the following lines to your `_config.yml` in order to tell Jekyll to use the plugin:

```
plugins:
- jekyll-workbox-plugin
```

## Getting Started

### Configuration

Add the following configuration block to Jekyll's `_config.yml`:
```yaml
pwa:
  sw_src_filepath: sw.js # Optional
  sw_dest_filename: sw.js # Optional
  precache_recent_posts_num: 5 # Optional
  precache_glob_directory: / # Optional
  precache_glob_patterns: # Optional
    - "{js,css,fonts}/**/*.{js,css,eot,svg,ttf,woff}"
    - index.html
  precache_glob_ignores: # Optional
    - "fonts/**/*"
```

Parameter                 | Description
----------                | ------------
sw_src_filepath           | Filepath of the source service worker. Defaults to `sw.js`
sw_dest_filename          | Filename of the destination service worker. Defaults to `sw.js`
precache_glob_directory   | Directory of precache. [Workbox Config](https://developers.google.com/web/tools/workbox/get-started/webpack#optional-config)
precache_glob_patterns    | Patterns of precache. [Workbox Config](https://developers.google.com/web/tools/workbox/get-started/webpack#optional-config)
precache_glob_ignores     | Ignores of precache. [Workbox Config](https://developers.google.com/web/tools/workbox/get-started/webpack#optional-config)
precache_recent_posts_num | Number of recent posts to precache.

### Write your own Service Worker

Create a file `sw.js` in the root path of your Jekyll project. You can change this source file's path with `sw_src_filepath` option if you don't like the default.

Now you can write your own Service Worker with [Workbox APIs](https://developers.google.com/web/tools/workbox/reference-docs/latest/), including a line `workbox.precaching.precacheAndRoute([]);`, which will be re-written by this plugin according to the precache configuration specified in the `_config.yml` file.

Here's what the `sw.js` like in my site.
```javascript
// sw.js

// set names for both precache & runtime cache
workbox.core.setCacheNameDetails({
    prefix: 'benediktmeurer.de',
    suffix: 'v1',
    precache: 'precache',
    runtime: 'runtime-cache'
});

// let Service Worker take control of pages ASAP
workbox.skipWaiting();
workbox.clientsClaim();

// default to `networkFirst` strategy
workbox.routing.setDefaultHandler(workbox.strategies.networkFirst());

// let Workbox handle our precache list
// NOTE: This will be populated by jekyll-workbox-plugin.
workbox.precaching.precacheAndRoute([]);

// use `Stale-while-revalidate` strategy for images and fonts.
workbox.routing.registerRoute(
    /images/,
    workbox.strategies.staleWhileRevalidate()
);
workbox.routing.registerRoute(
    /^https?:\/\/fonts\.googleapis\.com/,
    workbox.strategies.staleWhileRevalidate()
);
```

Make sure to follow the [Service Worker Checklist](https://developers.google.com/web/tools/workbox/guides/service-worker-checklist) from the Workbox documentation, specifically insert this snippet in your JavaScript code somewhere

```js
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
      navigator.serviceWorker.register('/sw.js');
  });
}
```

i.e. put it inline into the header of every page

```html
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
        navigator.serviceWorker.register('/sw.js');
    });
  }
</script>
```

or into your JavaScript bundle. And also make sure to set the `Cache-Control` HTTP header to `no-cache` for the `sw.js` file. For example when using [Netlify](https://www.netlify.com) just put this snippet into your `_headers` file:

```
# _headers
/sw.js
  Cache-Control: no-cache
```

Or if you're using [Firebase](https://firebase.google.com), put something like this into your `firebase.json` file:

```json
{
  "hosting": {
    /* ... */
    "headers": [
      {
        "source": "/sw.js",
        "headers": [{
          "key": "Cache-Control",
          "value": "no-cache"
        }]
      }
    ]
  }
}
```

# Contribute

Just fork this repository, make changes and submit a pull request, or just file a bug report.

# Copyright

Copyright (c) 2018 Benedikt Meurer.
Copyright (c) 2017 Pan Yuqi.

License: MIT

[ruby-gem]: https://rubygems.org/gems/jekyll-workbox-plugin