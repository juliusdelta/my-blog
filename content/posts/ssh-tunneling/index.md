---
title: "Using SSH Tunneling"
author: ["JD"]
date: 2021-03-01
tags: ["networking", "ssh"]
categories: ["networking"]
draft: false
description: "Use SSH Dynamic Port Forwarding/Tunnel to route web traffic."
ShowToc: true
TocOpen: true
---

Recently, I needed to figure out how to route _some_ internet traffic through another computer to access a private network. Dynamic port forwarding with SSH seemed to be the best solution for this type of thing. I don't know enough about SSH so this was a good place to dig in a little deeper and learn a few things. Once the tunnel was setup I decided to utilize Firefox's profiles feature in order to setup a SOCKS Proxy and ensure that only the web traffic I wanted was routed through the SSH tunnel.


## Setup {#setup}

I setup this tunnel in a rather simple way. Here's the man page entries for the relevant flags I used, `-D`, `-n`, and `-f`.

> -D [bind_address:]port
> Specifies a local "dynamic" application-level port forwarding.  This works by allocating a socket to listen to port on the local side, optionally bound to the specified bind_address.  Whenever a connection is made to this port, the connection is forwarded over the secure channel, and the application protocol is then used to determine where to connect to from the remote machine.  Currently the SOCKS4 and SOCKS5 protocols are supported, and ssh will act as a SOCKS server.  Only root can forward privileged ports.  Dynamic port forwardings can also be specified in the configuration file.
>
> -f
> Requests ssh to go to background just before command execution.  This is useful if ssh is going to ask for passwords or passphrases, but the user wants it in the background.  This implies -n.  The recommended way to start X11 programs at a remote site is with something like ssh -f host xterm. If the ExitOnForwardFailure configuration option is set to “yes”, then a client started with -f will wait for all remote port forwards to be successfully established before placing itself in the background.
>
> -n
> Redirects stdin from /dev/null (actually, prevents reading from stdin).  This must be used when ssh is run in the background.  A common trick is to use this to run X11 programs on a remote machine.  For example, ssh -n shadows.cs.hut.fi emacs &amp; will start an emacs on shadows.cs.hut.fi, and the X11 connection will be automatically forwarded over an encrypted channel.  The ssh program will be put in the background.  (This does not work if ssh needs to ask for a password or passphrase; see also the -f option.)


## Configuration {#configuration}

```bash
ssh [USER]@[IP_ADDR] -D [PORT] -N -f

# Useful alias
alias my_ssh_tunnel="ssh [USER]@[IP_ADDR] -D [PORT] -N -f"
```

As explained above in the documentation, the `-f` flag is the nifty one as that makes the connection and runs it in the background, but leaves open responses to ensure you can type in an ssh password if you need to. This is better than using the `[COMMAND] &` shortcut.

With that complete you can now navigate to \`about:profiles\` in Firefox and create a new one, launch it, and configure your network settings in it to use:

-   Manual Proxy Configuration
-   Input `127.0.0.1` and the specified `[PORT]` from the command
-   Select SOCKS v5
-   Enable Proxy DNS using SOCKS v5 and disable use DNS over HTTPs (if configured)

Now, only that profile will have it's web traffic routed through the SSH tunnel. Your regular profile will be directly connected. That's it!


## Launching Firefox {#launching-firefox}

You can now launch Firefox pretty easily by using `firefox -P [PROFILE] &`. Make sure you configure your default profile as you want to ensure you don't send unnecessary traffic through the proxy.
