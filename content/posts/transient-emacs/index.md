---
title: "Transient Menus in Emacs pt. 1"
author: ["JD"]
date: 2024-11-13
tags: ["emacs", "tools", "transient"]
categories: ["emacs"]
draft: false
description: "Building custom Transient menus is a great way to enhance day to day workflows"
ShowToc: true
TocOpen: true
cover:
  image: "posts/transient-emacs/transient.png"
  alt: "emacs transient menu"
  caption: "Image taken from the amazing [Jonas Bernoulli](https://emacsair.me/), developer of Magit & Transient"
  relative: "true"
---

[Magit](https://magit.vc/) is an innovative package that provides an amazing interface over git. The complexity of its UI is completely hidden away thanks to another package born out of Magit called [Transient](https://www.gnu.org/software/emacs/manual/html_mono/transient.html). Transient is so innovative that it was added to emacs core in 2021. Understanding at least the basics of Transient can provide alot of value in building tools to enhance various workflows.

{{< figure src="magit.png" >}}

[From the official manual](https://magit.vc/manual/transient/)

> Transient is the library used to implement the keyboard-driven “menus” in Magit. It is distributed as a separate package, so that it can be used to implement similar menus in other packages.

[From Transient Showcase](https://github.com/positron-solutions/transient-showcase)

> Transient means temporary. Transient gets its name from the temporary keymap and the popup UI for displaying that keymap.


## Foundation {#foundation}

A Transient menu is made of up of 3 parts: `prefix`, `suffix` and `infix`.

-   **Prefix**: represents a command to "open" a transient menu. For example `magit-status` is a prefix which will initialize and open the `magit-status` buffer.

-   **Suffix**: represents the "output" command. This is whats invoked inside of a transient menu to perform some kind of operation. For example in `magit` calling `magit-switch-branch` is a suffix which has a `(completing-read)` in front of it.

-   **Infix**: represent the "arguments" or the intermediary state of a transient. For example, adding `-f, --force-with-lease` means you're using an infix for the `magit-push` suffix.

There are 2 additional things to understand about transients:

-   Suffixes can call prefixes allowing for "nesting" of "menus." In `magit` when a commit is at point and you call `magit-diff` that is a suffix that is a _really_ just a prefix with it's own set of infixes and suffixes. See Example 3 below for a more elaborate example of this.
    -   Think of it this way: `Prefix -> Suffix -> Prefix -> ...`
-   State can be persisted between Suffixes and Prefixes to build very robust UIs that engage in very complex behavior while exposing a simple view to the user.

> Note: I don't go over state persisting through prefixes in the post. I do plan on doing a follow up for more complex situations as I continue to learn.


## Define {#define}

While the actual model is much more complex than I've lead on and has many more domain concepts to understand than I'm going to layout, defining simple transients can enhance your workflow in meaningful ways once you at least understand the basics. This is by no means a comprehensive guide on Transients but merely a (hopefully) educational and useful overview. For an incredible guide, checkout [positron-solutions Transient Showcase](https://github.com/positron-solutions/transient-showcase) which is one of the most thorough guides I've ever seen. If any information I share here is different in Positrons guide, trust Positron.

_**Note:** Each of the Examples work and can be evaluated inside of Emacs and I encourage you to do so!_


### 1 Prefix ➡️ 1 Suffix {#1-prefix-️-1-suffix}

Lets define a simple transient to just output a message.

```emacs-lisp
(transient-define-prefix my/transient ()
  "My Transient"
  ["Commands" ("m" "message" my/message-from-transient)])

(defun my/message-from-transient ()
  "Just a quick testing function."
  (interactive)
  (message "Hello Transient!"))
```

Once evaluated, `M-x my/transient` can be invoked and a transient opens with one suffix command `m` which maps to `my/message-from-transient` and outputs a message to the minibuffer.

{{< figure src="example-1.gif" >}}


#### Explain {#explain}

`transient-define-prefix` is a macro used to define a simple prefix and create everything Transient needs to operate. The body is where we define our Transient keymap, which in this case is called `"Commands"`. The body can define multiple sets of keymaps and each one should be defined as a vector where the first element is the "name" or "title display" of the current set of commands, and the subsequent N number of lists make up the whole map. The lists are in the format of (but not limited to) `(KEY DESCRIPTION FUNCTION)`. The `FUNCTION` arg must be `interactive` in order to work.

There are a handful of other ways to define the Transient elements, but we'll stick with this simple version. If you're interested in more complex methods refer back to Positrons guide.

Lets expand our example a bit by adding arguments and switches.


### 1 Prefix ➕ 2 Infix ➡️ 1 Suffix {#1-prefix-2-infix-️-1-suffix}

Here we will add 2 types of arguments: switches and arguments with a readable value.

```emacs-lisp
(transient-define-prefix my/transient ()
  "My Transient"

  ["Arguments & Switches"
    ("-s" "Switch" "--switch")
    ("-n" "Name Argument" "--name=")]

  ["Commands"
    ("m" "message" my/message-from-transient)])

(defun my/message-from-transient (&optional args)
  "Just a quick testing function."
  (interactive (list (transient-args transient-current-command)))
  (if (transient-arg-value "--switch" args)
    (message
      (concat "Hello: " (transient-arg-value "--name=" args)))))
```

Now we have a transient that gives us 2 infixes or "arguments".

-   `-s` is the keymapped function to toggle the `--switch` argument. A good example of this is a terminal command like `ls -a` where `-a` is a boolean type value that toggles `all` on for `ls`.
-   `-n` is the keymapped function to prompt for a minibuffer input to enter in what's appended to the `--name=` argument.

Once evaluated we can now run the transient with `M-x my/transient` and then press `-` followed by `s` to toggle the `--switch` switch argument. Pressing `-` followed by `n` will engage the `--name=` argument which will generate a minibuffer prompt to read user input. Once a name is typed in and `Enter` is pressed the minibuffer prompt will finish and the value entered will be displayed in the Transient menu itself. Pressing `m` will run the suffix. With `--switch` toggled on a message should appear in the minibuffer: "Hello: " followed by the input to `--name=`. Performing the flow with `--switch` toggled _off_ results in nothing being displayed.

{{< figure src="example-2.gif" >}}


#### Explain {#explain}

The suffix changes on `my/message-from-transient` are minimal but very important. We need to make sure that it can _interactively_ take `args` which are passed in by our Transient when the suffix is executed. This is a list of the values of our infixes from our prefix. We can then use the helper function `transient-arg-value` which has the following docstring:

> For a switch return a boolean.  For an option return the value as
> a string, using the empty string for the empty value, or nil if
> the option does not appear in ARGS.

So when we do `(if (transient-arg-value "--switch" args) ...)` that gets cast into a boolean for us to use. We could pass it directly into something as well without having to cast it ourselves or rely on elisp to do it. It also gives us the value of `--name=` as a string so we can just pass it into `(message)`. There's some more flexibility with argument passing we'll get into in a further example.

The shorthand we're using to define infixes makes it easy to define these two types, a switch and arguments.


### 1 Prefix ➕ 2 Infix ➡️ 1 Suffix ➡️ 1 Prefix {#1-prefix-2-infix-️-1-suffix-️-1-prefix}

Lets expand our example by demonstrating the composability of transient menus. We'll perform essentially the same example as before but instead of just triggering a `(message ...)` function, our suffix will instead point to a prefix, based on the infix arguments.

```emacs-lisp
(transient-define-prefix my/transient ()
  "My Transient"

  ["Arguments & Switches"
    ("-s" "Switch" "--switch")
    ("-n" "Name Argument" "--name=")]

  ["Commands"
    ("m" "message" my/message-from-transient)
    ("c" "go to composed" my/composed-transient)])

(defun my/message-from-transient (&optional args)
  "Just a quick testing function."
  (interactive (list (transient-args transient-current-command)))
  (if (transient-arg-value "--switch" args)
    (message
      (concat "Hello: " (transient-arg-value "--name=" args)))))

(transient-define-prefix my/composed-transient ()
  "My Composed Transient"

  ["Arguments & Switches"
    ("-l" "Loop" "--loop")]

  ["Commands"
    ("x" "Execute" my/composed-suffix)])

(defun my/composed-suffix (&optional args)
  (interactive (list (transient-args transient-current-command)))
  (if (transient-arg-value "--loop" args)
      (my/transient)))
```

Now we have a transient that provides 2 infixes as before, but now has another suffix that is in fact a prefix, a "sub-menu"! Then it uses an infix to determine the subsequent action when the suffix is called. If the `--loop` argument is set to `true`, we then loop back to our original prefix as this commands suffix.


#### Explain {#explain}

Here we simply expand on everything we've learned up to this point and simply call a prefix _as a suffix_. This demonstrates the composability of transients in that we created a "sub menu" for our main transient. The example isn't truly relying on the infixes to determine the second suffix/prefix behavior but that's for a subsequent post. Refer to the resources listed below for more information on that. The concept here is important to grasp as it's the foundation for building complex structured menus with transient.

{{< figure src="example-3.gif" >}}


## Real World {#real-world}

The usefulness of creating your own transients goes far beyond just developing packages. At my day job I use a transient menu to run our test suite. While I'm not a fan of how our test suite is setup, I wanted to make it as painless to interact with as possible.


### Overview {#overview}

I work on a Ruby on Rails application that utilizes Minitest. In the command line you can normally run the following `bin/rails test path/to/test.rb` and the suite will run. You can also optionally provide a line number to run a specific test instead of a whole file like `bin/rails test path/to/test.rb:50`. While there is a litany of ways to improve this experience with tools like `FZF`, I don't want to break my flow by switching windows.

Unfortunately,we also use environment variables that dictate additional behavior for our test suite such as providing specific database seeds, or running selenium on a headless browser live so you can debug end to end tests. While there are better ways to manage complex test suites, I'll make do with it and let emacs handle the annoying stuff.

At the end of it all, I end up with a test command that looks like: `SKIP_SEEDS=true MAGIC_TEST=0 PRECOMPILE_ASSETS=false rails test path/to/test.rb`. Typing that sucks, and setting them by default in my shell doesn't do much because they change so often in my normal work. So I wrote a transient menu to make things easy for me.


### Commander.el {#commander-dot-el}

I named it `commander.el` even though it's not a package I'm providing publicly. It's just for me and I wanted a cool name to keep it separate from my normal configuration files.

```emacs-lisp
(transient-define-prefix jd/commander ()
       "Transient for running Rails tests in CF2."
       ["Testing Arguments"
        ("s" "Skip Seeds" "SKIP_SEEDS=" :always-read t :allow-empty nil :choices ("true" "false")
         :init-value (lambda (obj) (oset obj value "true")))

        ("a" "Precompile Assets" "PRECOMPILE_ASSETS="
         :always-read t
         :allow-empty nil
         :choices ("true" "false")
         :init-value (lambda (obj) (oset obj value "false")))

        ("c" "Retry Count" "RETRY_COUNT=" :always-read t :allow-empty nil
         :init-value (lambda (obj) (oset obj value "0")))

        ("-m" "Magic Test" "MAGIC_TEST=1")]

       ["Testing"
        ("t" "Run Test" commander--run-current-file)
        ("p" "Run Test at Point" commander--run-command-at-point)
        ("f" "Find test and run" commander--find-test-and-run)]

       ["Commands"
        ("d" "Make dev-sync" commander--dev-sync)

        ("r" "Rails" jd/rails-commander)])

;; ...

(defun commander--run-current-file (&optional args)
  "Suffix for using current buffer-file-name as relevant test file."
  (interactive (list (transient-args 'jd/commander)))
  (commander--run-command (concat (mapconcat #'identity args " ") (commander--test-cmd (commander--current-file)))))

(defun commander--find-test-and-run (&optional args)
  "Suffix for using completing-read to locate relevant test file."
  (interactive (list (transient-args 'jd/commander)))
  (commander--run-command (concat (mapconcat #'identity args " ") (commander--test-cmd (commander--find-file)))))

(defun commander--run-command-at-point (&optional args)
  "Suffix for using current buffer-file-name and line-at-pos as relevant test."
  (interactive (list (transient-args 'jd/commander)))
  (commander--run-command (concat (mapconcat #'identity args " ") (commander--test-cmd (commander--current-file-at-point)))))

;; ...

(defun commander--run-command (cmd)
  "Runs CMD in project root in compilation mode buffer."
  (interactive)
  (when (get-buffer "*commander test*")
    (kill-buffer "*commander test*"))
  (with-current-buffer (get-buffer-create "*commander test*")
    (setq compilation-scroll-output t)
    (setq default-directory (projectile-project-root))
    (compilation-start cmd 'minitest-compilation-mode)))
```

I have this bound to `<leader> r` which for me is `SPC r`. This allows me to toggle on any environment variables and essentially build the testing command I need. I then use `(compilation-start COMMAND)` to run my test in a controlled popup buffer so I can easily see the results while I'm continuing to code. I've also set up `commander--run-current-file` and `comander--run-command-at-point`. `commander--run-current-file` will just run the generated command for the file that open in the current buffer. So `...env vars rails test path/to/test.rb`, while `commander--run-at-point` will run the command and include the number line at the current cursor point, so I can just run a single test without any issue.

This has sped up my workflow tremendously and made testing way faster for me as I don't have to bother with building a command from scratch, but I can instead just build it with a transient.


## Conclusion {#conclusion}

Hopefully this post has provided some inspiration for you to get into building transient menus. I'm still pretty new to elisp and learning about transient.el so there maybe some inaccuracies here and there. I also elected to use the `transient-define-prefix` macro instead of the more formal methods for creating a transient, but the macro is probably sufficient for most use cases like mine.

Below are links to resources that helped to expand my own knowledge and even inspire this post. A big shout out goes to Jonas for creating such an incredible package as well as positron-solutions for such a thorough guides through it all.


## Resources {#resources}

-   [Transient API Example by u/Psionikus: Part 1](https://old.reddit.com/r/emacs/comments/m518xh/transient_api_example_alternative_bindings_part_1/)
-   [Transient API Example by u/Psionikus: Part 2](https://old.reddit.com/r/emacs/comments/pon0ee/transient_api_example_part_2_transientdostay/)
-   [Official Transient Manual](https://www.gnu.org/software/emacs/manual/html_mono/transient.html)
-   [Transient Showcase by positron-solutions](https://github.com/positron-solutions/transient-showcase)
