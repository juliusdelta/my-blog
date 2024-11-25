---
title: "Kamal Tip - Private Network only Database Server"
author: ["JD"]
date: 2024-11-22
tags: ["rails", "kamal"]
categories: ["development"]
draft: false
ShowToc: false
TocOpen: false
---

****Edit****: In the original version of this post I made a mistake. This post has been corrected. See the details at the below for an explanation of the mistake and the solution.

<details>
<summary>Mistake Summary &amp; Solution</summary>
<div class="details">

> In the original version of this post I had stated that the App servers IP in the Kamal configuration should be set to it's public IP. This is incorrect. With the SSH proxy pointing at the public IP as well, this resulted in a jumphost connection problem, meaning it tried to connect to the public IP through a proxy of the public IP. This obviously didn't work and resulted in inconsistent behavior with Kamal. The solution was to replace the App servers IP address to be the private IP instead. As a result, the only place the public IP of the server is referenced is in the Kamal SSH proxy configuration.
</div>
</details>


## Updated Post {#updated-post}

I recently started a small side project and decided to use Rails 8 and Kamal. I've jumped on the [#nobuild](https://world.hey.com/dhh/you-can-t-get-faster-than-no-build-7a44131c) bandwagon (at least for this project) and thought I'd share a tip for all you non-dev-ops folks like me. I'm very new to the world of dev-ops and don't know or understand much by instinct yet so this may end up being something _very_ obvious for some folks. Hopefully someone in my position finds this useful.

⚠️ **Disclaimer** ⚠️: I am not a security expert by any means and I implement this in a pretty naive way so please do your own research before committing to using this approach in a production application with any kind of customer data.


## Cloud Resources {#cloud-resources}

Like the rest of the Rails community, I went with [Hetzner](https://www.hetzner.com/) for the time being because it's so cheap and easy to use. I configured 5 total resources so far:

-   App Server
-   DB Server
-   Private Network
-   2 Firewalls (rules)


### Private Network &amp; Firewall {#private-network-and-firewall}

I set up a private network resource to which I added the App and DB server. This allowed me to ensure that the 2 servers have a private communication channel that is inaccessible from the outside world. I set the IP subnet range to whatever arbitrary values I could easily remember and then allowed Hetzner to auto-assign IPs in that subnet to the servers when they were added to the network. For this example, I'll use `11.0.0.10` for the app server and `11.0.0.11` for the db server.

**Note**: The private network IP is different than the public IP of your server.

**Note**: Keep in mind these are explicit _allow_ rules which means "only X behavior is allowed."


#### App Server Firewall Rules {#app-server-firewall-rules}

Now that both resources could communicate via the private network, I decided to setup the first firewall to block off unnecessary ports on the App server.

-   Inbound Rules
    -   Allow traffic via TCP on port 443 (HTTPS)
    -   Allow traffic via TCP on port 80 (HTTP)
    -   Allow traffic from my personal IPs via TCP on port 22 (SSH)

The SSH port was configured to only allow a specific set of IPs so only my personal known IPs could SSH into the server. I think setting up a VPN is the most flexible/secure approach but I didn't go that far as this is just a small personal project.


#### DB Server Firewall Rules {#db-server-firewall-rules}

The DB server firewall received a much stricter set of rules.

-   Inbound Rules
    -   Allow traffic from `11.0.0.0/24` subnet via TCP on any port
    -   Allow traffic from `11.0.0.0/24` subnet via ICMP any port
    -   Allow traffic from `11.0.0.0/24` subnet via UDP any port

This setup ensures that any and all external traffic is blocked by the firewall. I can't even SSH into the DB server at the moment. I could lock this down even more by providing the specific subnet IP of the App server instead of using that entire subnet range but I don't think that's necessary.

Now that we have those (non-comprehensive) basics out of the way we'll talk about Kamal configuration.


## Kamal Setup {#kamal-setup}

I'm positive something isn't entirely set up properly here, but it all seems to work okay for me. You need to make sure that your Rails `config/database.yml` production configuration looks for the `DB_HOST` environment variable to set the host for the connection, otherwise copying my configuration directly won't work. I'm also using SolidQueue &amp; SolidCache, both of which are just running on my App server.


### `deploy.yml` {#deploy-dot-yml}

```yaml
# Used .env file to get spun up quickly. DON'T COMMIT SECRETS
<% require "dotenv"; Dotenv.load(".env") %>

service: my-app
image: docker-username/my-app
servers:
  web:
    - 11.0.0.10 # Use App Server private network IP
  job:
    hosts:
      - 11.0.0.10 # Same as App Server private network IP
    cmd: bin/jobs

proxy:
  ssl: true
  host: my-app.com

registry:
  server: registry.hub.docker.com # replace with your registry
  username: docker-username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
    - POSTGRES_PASSWORD
  clear:
    DB_HOST: 11.0.0.11 # Private network IP for DB server. This is important!
    POSTGRES_USER: db-user # replace with real value, rails defaults it to the project name
    POSTGRES_DB: my_app_production # same as POSTGRES_USER
    JOB_CONCURRENCY: 3
    SOLID_QUEUE_IN_PUMA: true
    RAILS_MAX_THREADS: 5

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole"

volumes:
  - "my_app_storage:/rails/storage"

asset_path: /rails/public/assets

builder:
  arch: amd64

# This is important! See below
ssh:
  proxy: root@1.1.1.1 # Replace with App Server public IP

accessories:
  db:
    image: postgres:15
    host: 11.0.0.11 # Private network IP for DB server.
    port: "5432:5432"
    env:
      clear:
        DB_HOST: my-app-db
        POSTGRES_USER: db-user # replace with real value
        POSTGRES_DB: my_app_production # replace with real value
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
```


### Explain {#explain}

The setup is pretty predictable as far as Kamal configurations go as I'm not doing anything fancy. The biggest gotcha here is that **at no point in the config am I referencing the DB server's public IP address**. Lets look at the `ssh` configuration to see how and why:

```yaml
ssh:
  proxy: root@1.1.1.1 # Replace with App Server public IP
```

This tells Kamal to use the App server as an SSH proxy to all the resources, and since our machines have SSH access to the App server already, **Kamal can connect to resources on the private network we setup because the App server is a member of that private network**. If you're not 100% following, here's a rundown ...

-   Since the public IP of the server is what Kamal needs to establish an SSH connection, proxy all SSH traffic _through_ the public IP of App server.
-   All SSH traffic from Kamal happens by Kamal establishing an SSH connection to the App server **first** then connecting to the App Server (again sort of) via it's internal network IP
-   Since we have access to the internal network through the proxy, we can also access the DB accessory on the internal network as well
-   So Kamal uses SSH through the App server public IP (as an SSH proxy) to manage the all the relevant services on the network

[The docs about configuring an SSH proxy are here](https://kamal-deploy.org/docs/configuration/ssh/#proxy-host). Unfortunately they aren't entirely clear if you don't already know what things like this command `ssh -W %h:%p user@proxy-ip` do, which I didn't when I started working on this configuration.


## Additional Resources {#additional-resources}

This post was geared mostly towards people still learning this stuff and want to use Kamal. Here's some additional resources that helped me out a lot while I was configuring everything:

-   [Kamal Documentation](https://kamal-deploy.org/) is useful, but it could be improved quite a lot
-   [Josef Strzibnys Blog](https://nts.strzibny.name/)
    -   Josef also authored [Kamal Handbook - The Missing Manual](https://kamalmanual.com/handbook/) which was mentioned postively by a lot of folks on various threads I saw about Kamal. I'll likely pick it up myself in my next round of book buys.
-   [Sam Johnsons Adding Postgres &amp; Redis to Kamal Video](https://youtu.be/CWisi8Xwh0M?si=OIgS8YjUJ51sDH_C)
    -   He demonstrates using Kamal v1, it was still really helpful to me to see someone configure everything from scratch.
