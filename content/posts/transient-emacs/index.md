---
title: "Transient Creating Menus in Emacs"
author: ["JD"]
date: 2024-03-27
tags: ["emacs", "tools", "transient"]
categories: ["emacs"]
draft: true
description: "Building custom Transient menus is a great way to enhance day to day workflows"
ShowToc: true
TocOpen: true
cover:
  image: "transient.png"
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

-   Suffixes can call prefixes allowing for "nesting" of "menus." In `magit` when a commit is at point and you call `magit-diff` that is a suffix that is a _really_ just a prefix with it's own set of infixes and suffixes. See Example N below for a more elaborate example of this.
    -   Think of it this way: `Prefix -> Suffix -> Prefix -> ...`
-   State can be persisted between Suffixes and Prefixes to build very robust UIs that engage in very complex behavior while exposing a simple view to the user.


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


## Resources {#resources}

-   [Transient API Example by u/Psionikus: Part 1](https://old.reddit.com/r/emacs/comments/m518xh/transient_api_example_alternative_bindings_part_1/)
-   [Transient API Example by u/Psionikus: Part 2](https://old.reddit.com/r/emacs/comments/pon0ee/transient_api_example_part_2_transientdostay/)
-   [Official Transient Manual](https://www.gnu.org/software/emacs/manual/html_mono/transient.html)
-   [Transient Showcase by positron-solutions](https://github.com/positron-solutions/transient-showcase)


## Real World {#real-world}

For work I developed a Transient menu to run some of the most commonly run tasks in my workflow.
