---
title: "Deploying Tanstack Start w/ Kamal"
author: ["JD"]
date: 2025-04-18
tags: ["tanstack-start", "kamal"]
categories: ["kamal"]
draft: false
description: "Deploying Tanstack Start with Kamal."
ShowToc: true
TocOpen: true
---

I come from the Ruby on Rails world and the latest popular tool in that community is [Kamal](https://kamal-deploy.org/). Kamal is a useful tool to quickly deploy a Rails application to a server and manage other deployed services through what Kamal calls "accessories." 

At my day job, I was tasked with building a small internal tool application using any framework I preferred, followed by deploying it to a suitable environment. I decided to use Tanstack Start and to run it on a plain old VPS. There are probably better hosting solutions, but due to the nature of the application, a VPS was perfectly sufficient. Since that was the case, I decided to go ahead and just use Kamal to manage deployments and make it easy for anyone else working on the application to do deploy as well.

So here is a small guide on deploying a Tanstack Start application with Kamal.

## Tanstack Start
[Tanstack Start](https://tanstack.com/start/latest) is a new full-stack javascript framework written by Tanner Linsley. I plan to write a longer overview of it at some point in the near future. It's definitely my top choice among the available React based frameworks on the market right now. As of this writing, Tanstack Start is in Beta status until they finish an underlying tooling migration at which point, they'll release V1.

## Kamal Overview
The main goal of Kamal is to streamline deployments into a simple, straightforward workflow.

1. Build a Docker image
2. Push the image to a registry
3. SSH into a server and pull down the image
4. Spin up the image on the server
5. Use Kamal-proxy to switch port mapping between old and new images, ensuring "0 down time deployments"
6. Shutdown the old image once health checks on the new image pass

All this can be run really simply on any machine as long as it has SSH access to the server.

## The Stack

- [Tanstack Start](https://tanstack.com/start)
- [Drizzle ORM](https://drizzle-orm.com/)
- [SQLite](https://www.sqlite.org/)
- [PNPM](https://pnpm.io/)

### Tanstack Start Configuration

There are 3 small tasks that need to be done in the Tanstack Start application to ensure everything works. First, if you're using Drizzle ORM, create a script in `package.json` to run migrations:

`${PROJECT_ROOT}/package.json`
```json
{
  // ...
  "scripts": {
    // ...
    "migrate": "npx drizzle-kit migrate"
    // ...
  }
  // ...
}
```

Keep in mind you'll need `drizzle-kit` as a regular dependency, not a `devDependency`. This is so we can easily run migrations everytime we deploy. Next, configure [Vinxi](https://vinxi.vercel.app/) through Tanstack Start's `app.config.js`, specifying the `node-server` preset to ensure optimization for a plain Node runtime rather than a platform like Cloudflare Workers.

`${PROJECT_ROOT}/app.config.js`
```js
export default defineConfig({
  // ...
  server: {
    preset: 'node-server',
  },
})
```

With that done we can test our build by just running `pnpm run build` (if you've followed the setup tutorial from the Tanstack Start documentation otherwise just use whatever build command you have.) By default, the assets are all placed in the `.output` directory and the main entrypoint to the application is `.output/server/index.mjs`. The application can be started with `node .output/server/index.mjs` in order to confirm everything is working as expected.

Now the final thing we need is a health check endpoint for Kamal Proxy to use in order to confirm the application is running. You can place this file wherever you'd prefer as long as it's an APIRoute-- I chose `src/routes/api/up.ts`. This location is configurable through Kamal's `proxy` settings. All this endpoint needs to do is return a 200 status code to a `GET` request. Here's what that looks like:

`${PROJECT_ROOT}/src/routes/api/up.ts`
```ts 
import { createAPIFileRoute } from "@tanstack/react-start/api"

export const APIRoute = createAPIFileRoute('/api/up')({
  GET: () => {
    return new Response()
  },
})
```

Now on to Docker.

### Docker Entrypoint

The entrypoint is a simple script that will run migrations and start the application everytime the Docker container is started. Here's what it looks like:

`${PROJECT_ROOT}/docker-entrypoint.sh`
```sh
#!/bin/sh

npm run db:migrate

node .output/server/index.mjs
```

Ensure this script has executable permissions by running `chmod +x docker-entrypoint.sh`. You can also add additional startup commands here if necessary.

### Docker Image

Here are a few notables to include in the Dockerfile:

- `node:20-slim` will be the base image
- Cache dependencies via `pnpm` so builds are faster
- A volume is required in order to have persistent data across deployments
- We need to set the environment variables for the application
- We need to ensure that any and all migrations for Drizzle ORM and our database are automatically run before the app spins up

`${PROJECT_ROOT}/Dockerfile`
```dockerfile
# Base image
FROM node:20-slim AS base

# Install & setup pnpm
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV NODE_ENV=production
ENV DB_FILE_NAME=file:<DATABASE_NAME>

RUN corepack enable

RUN mkdir /app
RUN mkdir /app/data && chmod 777 /app/data

VOLUME /app/data

COPY . /app

WORKDIR /app

# Install dependencies with a cache entry
FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

# Build the application
FROM base AS build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run build

# Copy deps and build output into main container
FROM base
COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/.output /app/.output

# Entrypoint execution permissions
RUN chmod +x /app/docker-entrypoint.sh

# Expose our port
EXPOSE 3000

# Start the server
CMD ["/app/docker-entrypoint.sh"]
```

Add a simple `.dockerignore` to ensure there are no file conflicts/overrides happening and that private files aren't copied into the container.

`${PROJECT_ROOT}/.dockerignore`
```dockerignore
# Version control
.git
.gitignore
.github

# Node.js
node_modules
npm-debug.log
yarn-debug.log
yarn-error.log
.pnpm-debug.log

# db
<DEV_DB>

# Build outputs
dist
.output
.nuxt
.next
.cache

# Environment variables
.env
.env.*
!.env.example

# OS generated files
.DS_Store
Thumbs.db

# Testing
coverage

# Logs
logs
*.log

# Temporary files
tmp
temp
```

### Kamal Configuration

The required Kamal configuration is relatively minimal since there aren't any accessories and a private network isn't being used. You can see my [previous post](/posts/kamal-tip-private-network) if you're curious about slightly a more complex configuration. Start things off by running `kamal init` to create the boilerplate files required by Kamal.

`${PROJECT_ROOT}/config/deploy.yml`
```yaml
# Name of your application. Used to uniquely configure containers.
service: <SERVICE_NAME>

# Name of the container image.
image: <IMAGE_NAME>

# Deploy to these servers.
servers:
  web:
    - <VPS_IP>
proxy:
  ssl: true
  host: <DOMAIN>
  app_port: 3000 # Must match what's exposed via the Dockerfile
  healthcheck:
    path: /api/up # Change this to match your healthcheck endpoint (optional)

# Credentials for your image host.
registry:
  password:
    - KAMAL_REGISTRY_PASSWORD

# Configure builder setup.
builder:
  arch: amd64
# Inject ENV variables into containers (secrets come from .kamal/secrets).
env:
  clear:
    DB_FILE_NAME: file:/app/data/<DATABASE_NAME>
  secret:
    - RANDOM_SECRET
ssh:
  config: true # Uses your `~/.ssh/config` file
  user: <SSH_USER> # The user you use to SSH into your VPS if not `root`
```

Most services rely on additional secrets that need to be set in the environment. [Kamal Secrets](https://kamal-deploy.org/docs/configuration/environment-variables/#secrets) is the default tool to handle this for Kamal.

With all that done you can now deploy your application by running `kamal setup`. This will SSH into the VPS, install Docker and Kamal Proxy, and begin the process of the first deploy.

### A Gotcha (maybe) - `permission denied` error

Kamal assumes that whatever credentials you use to SSH into the server log you in as the root user. This is very strange, especially considering you can change your `user` in the Kamal config to tell Kamal to use a different user when connecting. If it's the case that your user is _not_ the root user, you may run into an issue where the Docker daemon cannot be accessed. This will present itself as a `permission denied` error when trying to access the `docker.socket`. It completly prevents Kamal from spinning up the container.

In order to fix this you'll need `sudo` privileges and you simply have to add the user to the `docker` group. This can be done by running the following command on the server:

```bash
sudo usermod -aG docker <SSH_USER>
```

Be aware that adding your user to the docker group effectively grants root-level permissions. Therefore, it's critical to implement robust access controls and security measures to protect your environment.

Once completed, re-run `kamal setup`, on your local machine and the deployment should fire off without a hitch.

That's it! Happy coding.

## Links
- [Kamal](https://kamal-deploy.org/)
- [Kamal Secrets](https://kamal-deploy.org/docs/configuration/environment-variables/#secrets)
- [Tanstack Start](https://tanstack.com/start)
- [Drizzle ORM](https://drizzle-orm.com/)
- [SQLite](https://www.sqlite.org/)
- [PNPM](https://pnpm.io/)
- [My previous post using a private network with Kamal](/posts/kamal-tip-private-network)


