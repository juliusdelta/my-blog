---
title: "Using Run Command in Emacs for RSpec Watch Mode"
author: ["JD"]
date: 2021-02-02
tags: ["emacs", "tools"]
categories: ["emacs"]
draft: false
description: "I am a sucker for small micro-optimizations in my Emacs config. The Run Command package gives plenty of opportunity for that, while also building powerful automation opportunities. Here's the config I came up with for an RSpec watch mode."
ShowToc: true
TocOpen: true
---

[Run Command](https://github.com/bard/emacs-run-command) is a really nifty Emacs package that abstracts away running arbitrary shell commands into a nice ivy or helm (or other completion frameworks) frontend. I saw a few of the examples and immediately got an idea for using it to build an RSpec watch mode. It's a tiny optimization to my work flow as re-running the test command is just a few keystrokes in of itself, but getting automated feedback means I get to focus on other things while writing tests.


## The Config {#the-config}

The config is rather simple and only requires a couple of things to be setup. The biggest dependency is on an external tool called \`entr\` which watches for file changes and will re-run a command if it detects a change.


### Requirements {#requirements}

-   Emacs
    -   `run-command` installed
    -   `projectile` installed
-   System
    -   `entr` installed


### Recipes {#recipes}

Run Command is built on top of custom recipes you create in your config. These recipes define a list of similar functionality and each recipe is added to the recipe list `run-command-recipes`. Here is my recipe for RSpec:

```emacs-lisp
(defun jd/shell-command-maybe (exe &optional paramstr)
  "run executable EXE with PARAMSTR, or warn if EXE's not available; eg. (jd/shell-command-maybe \"ls\" \"-l -a\")"
  (if (executable-find exe) t nil))

(defun jd/get-current-line-number ()
  "Gets current line number based on `(what-line)` output. I'm sure there's a better way to do this but it's what I got."
  (car (last (split-string (what-line)))))

(defun run-command-recipe-rspec ()
  (list
     (list
      :command-name "RSpec Run File"
      :command-line (format "bundle exec rspec %s" (buffer-file-name))
      :working-dir (projectile-project-root)
      :display "Run RSpec on file")
     (list
      :command-name "Rspec Run Single"
      :command-line (format "bundle exec rspec %s:%s" (buffer-file-name) (jd/get-current-line-number))
      :working-dir (projectile-project-root)
      :display "Run RSpec on single block")
   (when (jd/shell-command-maybe "entr")
     (list
      :command-name "RSpec File Watch Mode"
      :command-line (format "find %s | entr -c bundle exec rspec %s" (buffer-file-name) (buffer-file-name))
      :working-dir (projectile-project-root)
      :display "Rerun rspec on file on save"))
   (when (jd/shell-command-maybe "entr")
     (list
      :command-name "Rspec Block Watch Mode"
      :command-line (format "find %s | entr -c bundle exec rspec %s:%s" (buffer-file-name) (buffer-file-name) (jd/get-current-line-number))
      :working-dir (projectile-project-root)
      :display "Rerun rspec on block on save"))))
```

The `run command-recipe-` name for the function is just a convention. That part of the name gets removed when run command lists your recipes. There's a couple of utility functions in there, namely `jd/shell-command-maybe` that is important. The implementation of the watch mode for RSpec requires that [entr](http://eradman.com/entrproject/) be installed on the system. I also thought it would be useful at some point in the future so I went ahead and abstracted it into my own namespaced function. If `entr` is not present on your machine the watch mode recipes will not be in the lists provided by run command during use. `jd/get-current-line-number` is also just a wrapper around `what-line` parsing. I'm sure there's a dedicated function to just get the number but I couldn't find it fast enough.

This works pretty well and does what it's intended. It allows me to run a file or block in "watch mode" while I'm developing or just run the spec with a few simple commands. Running `M-x run-command` will kick start your completion framework (which is auto detected) with a list of all your recipes. I've bound it to `SPC r c`. `SPC r` has become my default keymap as it's not used by anything from what I can tell.


### Run Command Configuration {#run-command-configuration}

According to the Run Commmand documentation it's recommended to use `M-x customize` command in order to add recipes to the list however, Doom Emacs does not support the `custom` interface, so I opted in to just set it manually:

```emacs-lisp
(setq run-command-recipes
      '(run-command-recipe-rspec))
```


## Ways to Improve {#ways-to-improve}

There are a few things I can do to improve this configuration and make it work more broadly and more like `jest` works for javascript. Using `projectile-rails` to find the matching spec file would be a good way to use it to. So if I'm editing `app/models/user.rb` I could make RSpec run a specific spec in "watch" mode to make TDD a little quicker. If I do that I'll update this post with the relevant code to do so.


## Conclusion {#conclusion}

I don't know A LOT of elisp but after troubleshooting and fumbling around, figuring it out was pretty fun. It's also yields a high reward as I get to use what I develop every day.
