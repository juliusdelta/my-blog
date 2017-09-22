---
title: My Dev Environment
layout: page
tags: development
date: 2017-04-11 20:53:18
thumbnailImagePosition: left
thumbnailImage: https://pbs.twimg.com/media/B_6dr4hU0AAAp6Q.png
coverImage: https://pbs.twimg.com/media/B_6dr4hU0AAAp6Q.png
---


I've spent a lot of time trying out different solutions for my dev environment since I started coding almost 2 years ago. Since then I've
developed very strong opinions about what I look for in an editor. 
<!--more-->

# Spacemacs
![Spacemacs](https://pbs.twimg.com/media/B_6dr4hU0AAAp6Q.png)

I started out using Atom, then migrated over to Vim. I loved modal editing. I hate using my mouse, so much so that I want to modify my WASD keyboard to use as a mouse with a specific layer config. 

My problem with Vim came in the form of productivity hell, where I would spend valuable hours working on my dotfiles instead of programming. Cue Spacemacs.

I heard about Spacemacs from a blog post by [jr0cket](http://jr0cket.co.uk/). I was really intruiged. I downloaded it and started to play around with it. Everything was already configured to work how I had vim working. Modifying things I found much easier spacemacs with it's easy `SPC f e d` and `SPC f e R` commands. It just simply took me seconds to make game changing modifications.


Maintaining packages is easy as it's just as simple as adding the appropriate line to install in your .spacemacs file. 

Spacemacs has become critical in my work flow. I anticipate posting many tutorials on how I use Spacemacs in the days to come.

# Terminal

I use iTerm2 with Oh-My-Zsh. Its pretty standard. Auto completion, syntax highlighting, easy theme managment all make my life just easier.

# Org Mode

One of the absolute best things about Emacs is org-mode. A heart a quote at a meetup recently that really described how I feel about emacs:
> Emacs is an operating system with a text editor on top. 
How true that is. 

Org mode allows you to organize you're entire life basically if you want to. I have a wide range of things I do in Org mode including to-do lists, notes, presentations, and I'm working on converting my budget to an Org mode table. It's not tedious in Org mode, it's more tedious to use the mouse to click around for options. It only takes me a few minutes to learn the short cut I need for the action I have to take. It's much more intuitive than using a mouse in my opinion.

I'll post a tutorial on using Org mode here soon so you can better understand what I'm doing.

**Here's a great resource for getting started with Org Mode**

<iframe width="560" height="315" src="https://www.youtube.com/embed/SzA2YODtgK4?rel=0" frameborder="0" allowfullscreen></iframe>

# Dotfiles

I haven't come around to uploading my .spacemacs to Github yet, but once I clean it up a bit I will. There's a few features I use like showing the git diff when I edit a file. I use that an a custom script to allow copy and paste to my system clipboard in the terminal version of Spacemacs. Normally you can use the OSX layer to do this, however it's currently broken, which for me doesn't make that big of a difference. 

# Other Editor

In the event that I pair program with someone who doesn't use Spacemacs (which is all the time currently), I use VSCode. It's a great editor that is more stable than Atom in my experience. The integrated terminal along with debugging features makes it a really great choice. 






