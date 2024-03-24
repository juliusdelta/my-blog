---
title: "Dockerize Create React App"
author: ["JD"]
date: 2021-01-02
tags: ["react", "docker"]
categories: ["development"]
draft: false
description: "I'm relatively new to using Docker and wanted a quick way to spin up a small React application using Docker so I could easily share it as a proof of concept for features I develop at work. Here's a quick guide to dockerizing a React app made with create-react-app."
ShowToc: true
TocOpen: true
---

I've used Docker quite a bit but I haven't really dived into configuring my own dockerized app. I recently needed to build a quick proof of concept with a React app and needed to share it easily without worrying too much about build dependencies or anything of the sort. So here's a quick guide on dockerizing an app created with create-react-app.


## The guide {#the-guide}

I'll assume you already have a CRA app created. If you've never used create-react-app, I recommend checking out the docs [here](https://reactjs.org/docs/create-a-new-react-app.html). This tutorial will work from the top down and both the `Dockerfile` and `docker-compose.yml` files will be at the end in full.

Create a `Dockerfile` at the root of your application. First we need to figure out what base image we're going to use. I'm biased towards the Alpine based ones cause those are lite and quick to spin up. So we'll use `node:current-alpine3.10`. This tells Docker to pull the current alpine 3.10 image from Dockerhub.

```dockerfile
FROM node:current-alpine3.10
```

Next we'll need to set the working directory, where the app will be "put", dependencies will be installed in, and our run command to run.

```dockerfile
WORKDIR /app
```

We'll setup the `PATH` to ensure that the \`node_module\` binaries are accessible globally.

```dockerfile
ENV PATH /app/node_modules/.bin:$PATH
```

Next is probably the part that confused me the most when working with Docker. We have to copy over critical files to ensure that the container knows where to get our dependencies and how to build them all. This step needs to be done explicitely and not make use of a volume due to the fact that it'll overwrite dependencies if you're not careful.

```dockerfile
COPY package.json ./
COPY yarn.lock ./
```

This ensure that just the dependency and depenency lock file are both available to the container. We _could_ just copy over the `node_modules` folder from our local machine into the container, but it's likely that something will break cause sometimes certain modules are built differently for different targets.

Next we'll tell the container to install the dependencies.

```dockerfile
RUN yarn install
```

Finally we'll tell the container to execute our build/run command. This command is important cuase it represents the "main" process for our image which is why this is `CMD` instead of `RUN`.

```dockerfile
CMD ["yarn", "start"]
```

Before we move on we'll need to go ahead and setup the `docker-compose.yml` and `.dockerignore` files to ensure everything runs as inteneded. The convience of docker-compose is that you don't have to pass 100 args to the Docker CLI.

Lets setup the `.dockerignore` first.

```dockerignore
node_modules
build
.dockerignore
Dockerfile
```

This ensures that Docker doesn't use the node_modules or `build` directory in the volume we create in the `docker-compose.yml`. Not ignoring the `node_modules` directory will result in our previously installed dependencies being overwritten by what's on our local machine. So lets make sure the container uses the dependencies it has.

Ok now for the last bit, the docker-compose file. Here we declare a version, the service/container_name and then pass the actual configuration. We need to tell docker to use the current directory as it's main "context" and subsequently use the Dockerfile in that directory.

```yaml
version: '3.3'

services:
  wc-concept:
    container_name: wc-auth-concept
    build:
      context: .
      dockerfile: Dockerfile
```

Now we have to define Volumes. Volumes can be used for persistant reference between Docker container builds. Since each container is meant to be spun up and destroyed with no lingering side effects, volumes represent a way to tell Docker about persistant information. This can be a database file or in our case, the code. This tells docker to reference the code in `.` which is our local project directory as the code in `/app` which is the directory of the application code in the container. We also add a node_modules volume to ensure we don't have to constantly download them whenever the container spins up.

```yaml
version: '3.3'

services:
  wc-concept:
    container_name: wc-auth-concept
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - '.:/app'
      - '/app/node_modules'
    ports:
      - 3001:3000
    environment:
      - CHOKIDAR_USEPOLLING=true
```

There's 2 more things in the above example. First we define the port to expose out of the container and forward it to a port on our local machine. My project runs on `3000` by default, which is what Docker knows about. We'll expose port `3000` from the container and forward it to port `3001` on our local machine. The format is `local_port:container_port`. Finally we tell Docker to poll the volumes for changes so we can take advantage of `webpack-dev-server` or hot reloading.

Now you can just run `docker-compose up`, with the optional `-d` flag which is "detached" mode and it will run in the background instead of outputting to the terminal, and visit `localhost:3001`.

Here's all the code for all 3 files in one place for reference.

**Dockerfile**

```dockerfile
FROM node:current-alpine3.10

WORKDIR /app

ENV PATH /app/node_modules/.bin:$PATH

COPY package.json ./
COPY yarn.lock ./

RUN yarn install

CMD ["yarn", "start"]
```

**.dockerignore**

```dockerignore
node_modules
build
.dockerignore
Dockerfile
```

**docker-compose.yml**

```yaml
version: '3.3'

services:
  wc-concept:
    container_name: wc-auth-concept
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - '.:/app'
      - '/app/node_modules'
    ports:
      - 3001:3000
    environment:
      - CHOKIDAR_USEPOLLING=true
```

This worked just fine for my purposes. I'm sure there's more to be done to make this Docker configuration way more robust. Enjoy.
