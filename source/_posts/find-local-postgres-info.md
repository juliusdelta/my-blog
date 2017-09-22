---
title: Finding Your Local PostgreSQL Info
layout: page
date: 2017-08-31 19:47:09
categories:
- programming
tags: 
- databases
- postgresql
thumbnailImagePosition: "left"
thumbnailImage: https://i.imgur.com/PJgoZfR.png
---

I ran into a snag while trying to configure [diesel](https://diesel.rs) to run locally so I can develop a [Rust API](https://github.com/juliusdelta/rust-rocket-api). Just thought I'd share a tip for figuring out some PostgreSQL info.
<!-- more -->

### Installation

Postgres can be installed locally with [Homebrew](https://brew.sh/). Run `brew install postgresql` and you should see a whole bunch of documentation being printed to the terminal. As long as you don't see any very explicit error messages you should be good. Now we should make sure that postgres starts on startup by running `pg_ctl -D /usr/local/var/postgres start && brew services start postgresql`. This sets up Postgres to run in the background on startup. We can make sure everything went well by running `postgres -V` to get the version.

### Moving Forward

Postgres works fairly seemlessly out of the box. A users table is created which gives you among other users you create different levels of access to databases. That's a very deep topic and there's a lot to cover there, so I'll simply refer to this great [cheatsheet by apolloclark](https://gist.github.com/apolloclark/ea5466d5929e63043dcf).

So lets talk about finding your connection info. You can initiate the commandline SQL interface by executing `psql postgres`. This will open up the very root of your Postgres databases. Here you can run `\conninfo` in order to obtain the information for your current connection including your port.

```sql
postgres=# \conninfo
You are connected to database "postgres" as user "user" via socket in "/tmp" at port "5432".
```

The default port is `5432`, which can be changed if necessary. You can refer to the cheatsheet if you need to.

## That's it

I had some difficulty figuring this out for the first time. For some additional resources there's this great blog, [Getting Started with Postgresql on Mac OSX](https://www.codementor.io/devops/tutorial/getting-started-postgresql-server-mac-osx) which can provide some additional help on the matter.
