---
title: "Quick Tip: Git - Rebasing Branches"
author: ["JD"]
date: 2024-10-11
tags: ["git"]
categories: ["development"]
draft: false
description: "A quick tip when dealing with branches off branches."
ShowToc: false
TocOpen: false
---

I'm a big believer in keeping a clean commit history. This practice isn't always necessary depending on the type of work being done, but I frequently reference old commits, so keeping the merge commits out of my history just helps me to get rid of the noise. This means, that I rebase my branches often which can cause an issue when branching off branches, as once a branch is merged into the `main` branch, you need to catch up your currently working branch some how.

So here's the process I follow to make sure that all my branches stay up to date. Lets say I'm working on `branch-B` which is branched off `branch-A` which itself is branched off `main`.

****Note:**** You can see a similar output to this by doing `git log --pretty=oneline`.

```shell
# branch-B commits
b-3
b-2
b-1
a-3 (branch-A)
a-2
a-1

# branch-A commits
a-3
a-2
a-1
```

Lets say `branch-A` gets merged to main via a merge commit. The merge commit squashes `a-1,2,3` into a single commit and now `main` has all the changes on the remote origin. Now we're left with `branch-B` which looks like:

```shell
b-3
b-2
b-1
a-3
a-2
a-1
```

The fix is really encapsulated into a single command, but before we do that we have to ensure our local `main` is up to date so it has those changes.

```shell
$ git checkout main
$ git pull
```

Now that the local version of `main` is up to date we can now rebase `branch-B` onto `main` from `branch-A`. The `git` command almost reflects that sentence perfectly.

```shell
$ git checkout branch-B
$ git rebase --onto main branch-A
```

What happens here is that `branch-B` upstream changes from `branch-A` to `main` but with gits knowledge of what happened to `branch-A` which in this case was a merge commit. This means, that the merge commit is honored, and only the commits from `branch-B` proper are re-applied. So after this the history of `branch-B` looks like:

```shell
# branch-B commits
b-3
b-2
b-1
```

...while the upstream is now `main`.

****Note:**** It's important that you make sure your local `main` has that merge commit in it's history otherwise you'll end up with weird conflicts.
