---
title: "Resolving client side routes in Rails"
author: ["JD"]
date: 2021-01-09
tags: ["ruby", "rails", "tips"]
categories: ["development"]
draft: false
description: "Tell Rails to pass routes to a client with a nifty helper."
ShowToc: true
TocOpen: true
---

There's a quick and easy way to satisfy client side routing in a Rails application. Rails will automatically try to resolve it's routing on the server side and throw an immediate 404 if no valid pages exist. Since my main application at work is a React SPA I needed a way to resolve routes to the client and not let them get caught by the server and throw a 404. The `(/*path)` method route 'helper' allows through any route so it can then be handled elsewhere.

```ruby
get '/app(/*path)', to: 'my_app#index'
```

So anytime you visit say `/app/123` the `/app` route will correctly be resolved to the `MyAppController#index` method and any other parameters will be left for you to parse and decide what to do with on the client side.

You can optionally add `constraints` to ensure that the default Rails behavior kicks in if the route is in fact invalid.

```ruby
get '/app(/*path)', to: 'my_app#index', constraints: {path: /(profile|home)\/.*/}
```

This makes `/app/home` and `/app/profile` completely valid, and passes Rails routing checks, but anything else like `/app/message` would be invalid to Rails and thus trigger the Rails server side 404 error.

Using `constraints` is great if you have very simple routing, that doesn't use any dynamic arguments, like an `ID` but that's a very tight use case. Normally I'd recommend against this because you'll have to maintain your routes in 2 places, `routes.rb` and your client code. It's very easy to handle 404 errors with something like \`react-router\` so that would probably be more preferable long term.
