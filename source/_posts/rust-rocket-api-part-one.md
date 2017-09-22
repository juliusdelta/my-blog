---
title: Rust Rocket Api Part 1
layout: page
date: 2017-09-15 23:02:23
categories:
- programming
tags: 
- rust
- diesel
- rocket
- cargo
coverImage:
coverSize: partial
metaAlignment: center
coverMeta: out
thumbnailImage: https://i.imgur.com/WtLvYje.png
thumbnailImagePosition: left

---

I figure that the best way to learn a programming language is simply to just use it to build stuff. So I decided to build a simple JSON API using Rust, [Diesel](https://diesel.rs) as the ORM and [Rocket](https://rocket.rs) as the web framework.<!--more--> This is simple enough to not _really_ have to use either one, but I imagine over time that this project will grow in complexity, leaving Diesel and Rocket to be good choices for tools.

**Disclaimer:** I'm going to assume little to no knowledge of Rust so I will go into quite a lot of detail over several articles. 

## The Challenge

Build a simple JSON Web API to return even simpler movie data using Rust. The movies table is fairly simple, with one set of records for `movies` with `id`, `title`, `director`, and `rating` columns. We need to be able to `GET`, `POST`, `PUT`, and `DELETE` data and of course be able to access it from the web.

## Starting

You need to install Rustup, which is a bit like [RVM](http://rvm.io/) or [RBENV](http://rbenv.org/) if you're familiar with Ruby. All the instructions for installing Rust can be found [here](https://doc.rust-lang.org/1.13.0/book/getting-started.html). I definitely recommend going through, at least, the Getting Started part of the tutorial where you'll learn about running Rust in the command line and also using Cargo, Rust's package manager. Rocket isn't compatible with Stable Rust, so we'll need to use Nightly. The guide for installing nightly can be found [here](https://doc.rust-lang.org/1.13.0/book/nightly-rust.html).

Ok. So now we should be running Nightly Rust and have all the neccessary tools installed to start building the app.

Hop into your code directory in your commandline and generate a new cargo crate with the binary flag so it can be executed as it's own application.

Go ahead and run:
```bash
$ cargo new rust-rocket-api --bin
```
You should see output similar to this.
```rust
$=> Created binary (application) `rust-rocket-api` project
```

You'll see a new directory has been created called `rust-rocket-api` and we can now `cd` into it.

I'll explain the files created soon, but first lets run it to make sure it works. Cargo initiated the project with a `Hello World!` program hanging out inside. So we'll run the application with:

```bash
$ cargo run
```
If everything is good you should see:
```rust
$=> Compiling rust-rocket-api v0.1.0 (file:///Users/your/code/path/rust-rocket-api)
     Finished dev [unoptimized + debuginfo] target(s) in 1.22 secs
      Running `target/debug/rust-rocket-api`
Hello, world!
```

## Project Structure

Our files so far are as follows:
```
> rust-rocket-api 
   |-> Cargo.toml
   |-> src
     |-> main.rs
```

Cargo created a new directory with those files. Lets go through each of theme one by one. 

**Note:** When we ran `cargo run` the first time, it generated a couple extra things, `cargo.lock` & a `target` directory, but we'll get to those in the next article.

------

##### `Cargo.toml`:

This is where your dependencies will be located. This is sort of like the Ruby `.gemspec` file or, `package.json` with Node, or `Pip` for Python. This will contain not only dependency information, but also information about the versions, build, configuration options, and author. This is called a project `manifest`. Currently the manifest just contains information about the package and no dependencies. We'll change that soon.

##### `src/main.rs`:

This is the `main` file. This is sort of the "brain" of the application, where everything _begins_ to get executed. Your program will not run without this file, and it's corresponding `main()` function. It's important to understand, this was created using the `--bin` flag we passed into the `cargo new` command. This allows the program to be executed on it's own. If we _hadn't_ passed that flag, then we would have created a `library`, with a corresponding `lib.rs` file instead. This cannot be executed as a stand alone application, but just as a dependency for another program.

------

## Rocket

Lets continue by setting up rocket and getting to a point where we can start the server. It should be pretty fast. The docs for Rocket can be found [here](https://rocket.rs).

We're basically going to do the "Hello World!" tutorial, spun for our project setup.

First, we need to tell our program that it depends on `rocket` and `rocket_codgen`. 

**Cargo.toml**
```rust
[dependencies]
rocket = "0.3.2"
rocket_codegen = "0.3.2"
```

Perfect. Now that that's in place we'll head into `src/main.rs` in order to configure rocket and declare the dependencies. Go ahead and clear out the stock "Hello World" functionality and enter this:

**src/main.rs**
```rust
#![feature(plugin)]
#![plugin(rocket_codegen)]

extern crate rocket;

#[get("/world")]
fn world() -> &'static str {
    "Hello World!"
}

fn main() {
    rocket::ignite().mount("/hello", routes![world]).launch();
}

```

The first line has `#![feature(plugin)]` and `#![plugin(rocket_codgen)]` simply tell the app that you're going to be using Rockets code generation features. On the following line we declare that we're importing an external crate, which of course is Rocket. 

Here's where stuff gets a little interesting.

The line `#[get("/world")]` is declaring the `world()` function as an attribute of `get`. You can see some of the related docs in [Rust by Example](https://rustbyexample.com/attribute.html) and here in [The Rust Book](https://doc.rust-lang.org/book/first-edition/attributes.html). When it comes to routing and requests, it's as simple as declaring the type of request as attribute, and then you set the value to the path, in this example `"/world"`.

So the `world()` function returns a [`&'static str`](https://doc.rust-lang.org/1.7.0/book/strings.html), `"Hello World!"`.

Next we have our `main()` function, which starts the rocket server and gives the information for the "index" path, which is the first argument in the `.mount()` method. then declares routes, then launches.

Now if you run `cargo run` the program will take a minute to compile, then you should see something similar to this:
```
    Finished dev [unoptimized + debuginfo] target(s) in 0.0 secs
     Running `target/debug/rust-rocket-api`
🔧  Configured for development.
    => address: localhost
    => port: 8000
    => log: normal
    => workers: 16
    => secret key: generated
    => limits: forms = 32KiB
    => tls: disabled
🛰  Mounting '/hello':
    => GET /hello/world
🚀  Rocket has launched from http://localhost:8000
```

Navigate to `http://localhost:8000/hello/world` and you can see the application running. 


In the next part of this article I'll be discussing setting up [Diesel](https://diesel.rs) and Postgres for us to use a database and start storing some data.
