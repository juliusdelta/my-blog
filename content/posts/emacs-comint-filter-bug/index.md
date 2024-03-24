---
title: "Finding an Emacs Bug"
author: ["JD"]
date: 2024-01-02
tags: ["emacs", "bugs", "comint"]
categories: ["emacs"]
draft: false
description: "I managed to come across an emacs bug.. or rather unexpected & undocumented behavior."
ShowToc: true
TocOpen: true
---

I was recently working on a porcelain for local database management in Emacs, `tablemacs` (name tbd). The general idea here is to give a magit style interface for interacting with a local database. This mode is built off `SQLi` (sql-interactive-mode) and uses a hidden `comint` buffer to execute commands. Everything was working great till I encountered a really weird issue. Let me preface everything with, I'm still **very** new to elisp and am still very much a beginner. Not only is it a radically different language than what I'm used to, the paradigms are also just very unique to emacs. If some of the code here looks wrong, it's a mistake in translation as some of it was modified for ease of understanding.


## The process &amp; the Issue {#the-process-and-the-issue}

Right now `tablemacs` creates a hidden `comint` buffer with `sql-interactive-mode` engaged. I then use `comint-redirect-send-command-to-process` which redirects the output of a comint command to an aribtrary buffer, which is my `tablemacs-status` buffer.

> (comint-redirect-send-command-to-process COMMAND OUTPUT-BUFFER PROCESS ECHO &amp;optional NO-DISPLAY)
>
> Documentation
>
> Send COMMAND to PROCESS, with output to OUTPUT-BUFFER.
> With prefix arg, echo output in process buffer.
> If NO-DISPLAY is non-nil, do not show the output buffer.

This works as you'd expect however, there's some artifacts in the output. Here's what I get for my `show-tables` command which just runs `show tables;`:

```shell
show tables;^ M
+--------------------------+^ M
| Tables_in_tablemacs_test |
+--------------------------+^ M
| test_table               |^ M
+--------------------------+^ M
```

All those =^M=s means it's displaying the carriage returns in the redirected buffer. Obviously, I wanted to remove those.

I searched around for something that could help and I had already known about comint filters. These allow you to run filter functions on the strings as they or after they've interacted with the comint buffer. Here's a non-comprehensive list of a few of the available "filters" list variables you can add filter functions too:

-   comint-input-filter-functions
-   comint-output-filter-functions
-   comint-preoutput-filter-functions
-   comint-redirect-filter-functions
-   comint-redirect-original-filter-function

There's a few more but those are the ones that were interesting to me in this situation. [Looking at the documentation](http://doc.endlessparentheses.com/Var/comint-redirect-filter-functions.html), `comint-redirect-filter-functions` seemed perfect.

> List of functions to call before inserting redirected process output.
> Each function gets one argument, a string containing the text received
> from the subprocess. It should return the string to insert, perhaps
> the same string that was received, or perhaps a modified or transformed
> string.
>
> The functions on the list are called sequentially, and each one is given
> the string returned by the previous one. The string returned by the
> last function is the text that is actually inserted in the redirection buffer.
>
> You can use \`add-hook' to add functions to this list
> either globally or locally.

Seems ok so far! So I plugged it in with:

```emacs-lisp
(add-hook 'tablemacs-minor-mode-hook (lambda () (push 'comint-strip-ctrl-m comint-redirect-filter-functions) ))
```

**It did not work.**


## Investigation {#investigation}

I then moved to setting the `comint-redirect-filter-functions` globally and still it did not work. I thought surely I was doing something wrong, but when I used `describe-variable` on `comint-redirect-filter-functions` it appeared to have `comint-strip-ctrl-m` as it should. I'm still a beginner when it comes to elisp so I thought I was doing something wrong. So I wrote my own filter just to see:

```emacs-lisp
(defun tablemacs--comint-strip-ctrl-m-test (str)
  "test filter"
  (message "ran filter!")
  str)
```

Low and behold I got the message in my minibuffer. So what gives?

Well the next thing to do was to look at `describe-function` for `comint-strip-ctrl-m` which is as follows:

```emacs-lisp
(defun comint-strip-ctrl-m (&optional _string interactive)
  "Strip trailing `^M' characters from the current output group.
This function could be on `comint-output-filter-functions' or bound to a key."
  (interactive (list nil t))
  (let ((process (get-buffer-process (current-buffer))))
    (if (not process)
        ;; This function may be used in
        ;; `comint-output-filter-functions', and in that case, if
        ;; there's no process, then we should do nothing.  If
        ;; interactive, report an error.
        (when interactive
          (error "No process in the current buffer"))
      (let ((pmark (process-mark process)))
        (save-excursion
          (condition-case nil
	      (goto-char
	       (if interactive
	           comint-last-input-end comint-last-output-start))
	    (error nil))
          (while (re-search-forward "\r+$" pmark t)
	    (replace-match "" t t)))))))
```

Herein lies the culprit. This filter takes in an `&optional _string` and usually, variables prefixed with `_` means they aren't used. So if it's not using the passed in string, what's it doing? Well it's using `(get-buffer-process (current-buffer))` and then marking where the process command output starts and then searching through with `(research-forward "\r+$" pmark t)` which is what actually replaces the carriage returns. The big red flag here is that it's using the `(current-buffer)` which, in my use case, isn't the buffer that the process is running in, instead its my porcelein buffer.

So the issue turned out to be the implementation of `comint-strip-ctrl-m` and not the way I was using it.


## What to do next? {#what-to-do-next}

It's pretty clear to me that the function of \`comint-strip-ctrl-m\` doesn't match the documentation. Emacs documentation is _exceptional_ compared to anything else I've used, I mean it's known as the "self documenting text editor" for a reason. However, this is a very specific case where the documentation, or expected implicit behavior derrived from the documentation, doesn't line up with reality. So what should I do?


### My fix {#my-fix}

In my code, I just wrote my own filter to do exactly `comint-strip-ctrl-m` should do. It looks like this:

```emacs-lisp
(defun tablemacs--comint-strip-ctrl-m (str)
  "Filter function to remove carriage returns from comint output
   This is needed because one provided by comint rely's on `current-buffer`
   to get the process and it's always going to be wrong."
  (replace-regexp-in-string "\r" "" str))
```

So this now works with `comint-redirect-filter-functions` as expected.

```shell
show tables;
+--------------------------+
| Tables_in_tablemacs_test |
+--------------------------+
| test_table               |
+--------------------------+
```


### Emacs bug report? {#emacs-bug-report}

At this point I'm considering filing a report, or at least a request to update the documentation for this rather specific small bug. It's not like this is a huge breaking bug for most users, and it's a pretty specific use case. But this might open up a potential contribution opporunity or at least a way to get involved with the emacs maintainer community at least a little bit. Possible fixes could consist of one of the following:

1.  Updating the documentation for `comint-strip-ctrl-m` to explictely state it uses `current-buffer` instead of just the passed in string.
2.  Updating `comint-strip-ctrl-m` to actually use the string it's passed and perform the same string editing functions.
3.  Creating a new `comint-strip-ctrl-m-filter` (name TBD?) which takes in a string, modifies it and returns a modified string.

I don't know. Maybe someone will let me know if this is in fact an issue or if I'm just missing something else important.

Happy Hacking.
