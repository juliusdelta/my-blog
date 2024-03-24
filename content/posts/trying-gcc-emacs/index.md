---
title: "Trying out GCC Emacs"
author: ["JD"]
date: 2021-02-20
tags: ["emacs"]
categories: ["emacs"]
draft: false
description: "I've always had complaints about emacs performance but the latest native compilation branch squashes any concerns I have with it."
ShowToc: true
TocOpen: true
---

I love Emacs. I've been using it since late 2017 and have had an on and off again relationship with it. It's a great tool for anyone who likes to tinker around with software. Like any relationship, there are some pain points I have that consistently want to push me away from Emacs, one of which is performance.

I've used [Doom Emacs](https://github.com/hlissner/doom-emacs) for a really long time and hlissner has done an incredible job of building a fantastic configuration setup, and compared to other configuration frameworks I've used, Doom is the most performant and most versatile. That being said, no matter how much optimization is done on the configuration side, Emacs can still be extremely slow, especially compared to it's Vim counterpart.


## Cue GCC Emacs {#cue-gcc-emacs}

GCC Emacs is a branch of the main Emacs repository that uses [libgccjit](https://gcc.gnu.org/onlinedocs/jit/index.html), a pseudo-JIT compiler which compiles elisp to native code. You can see all updates from the author [here](http://akrl.sdf.org/gccemacs.html) and try to understand exactly what's happening. This provides an exceptionally large performance boost in everything Emacs does from startup time to normal day-to-day work. It also appears to help manage the amount of C code that needs to be written in the underlying Emacs engines. See the [Emacs Wiki](https://www.emacswiki.org/emacs/GccEmacs) for more info on how it works and more detailed instructions than what I'm about to give.


## Get up and running {#get-up-and-running}

I've run this on Arch linux only so far so here are the steps I followed in order to get it running. [Here's the build documentation](https://git.savannah.gnu.org/cgit/emacs.git/tree/INSTALL) for more information on the flags used to configure and compile. Some used here can be omitted if you don't want them.

> Note: I highly advise against using the AUR package for GCC Emacs and instead just bulid it yourself

```shell
# Install libgccjit: https://aur.archlinux.org/packages/libgccjit/
$ yay -S libgccjit

# Install CMake (required for VTerm. Ignore if you want)
$ sudo pacman -S cmake

# Clone Emacs repo and checkout `feature/native-comp`
$ git clone git://git.savannah.gnu.org/emacs.git -b feature/native-comp
$ cd emacs

# Build
$ ./autogen.sh
$ ./configure --with-nativecomp --with-dbus --with-gif --with-png --with-jpeg --with-libsystemd --with-rsvg --with-modules
$ make -j$(nproc)
```

At this point you can run `./src/emacs` in the emacs directory and viola. It should start up pretty fast. At first I renamed my `.emacs.d` folder just so I could load up vanilla Emacs and test things out. If you want to use Doom like I am and/or use GCC Emacs fulltime, keep reading.

At this point I recommend you uninstall the normal Emacs version if you have it installed and then you can install this package proper.

```shell
# Remove Emacs (optional)
$ sudo pacman -R emacs

# In Emacs directory
$ make install
```

The emacs binary you reference should work just as intended. Now for Doom things are quite simple. If you changed the `.emacs.d` directory go ahead and change it back. You'll then want to run `./emacs.d/bin/doom upgrade` which will ensure you have the latest pinned commits of packages for increased chances of stability and build the packages as required.

**Warning**: This can take quite a while.


## It's fast {#it-s-fast}

It's been exceptionally fast for me. I also am using VTerm when I need to do anything in the terminal while working on something and it's a lot faster than in the standard release as well.

Cheers.
