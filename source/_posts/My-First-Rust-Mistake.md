---
title: My-First-Rust-Mistake
date: 2017-07-14 21:19:33
tags: rust
---

I've been tinkering with Rust the last few days, as I'm planning to build a simple api application over the next few days. What's fascinating to me is all the tiny mistakes I make when I'm just trying to learn rust code. The first programming language I became really familiar with was Ruby, but learning something as complex as Rust is way different. I'm contemplating making a small list of postings surrounding the tiny errors I make in hopes to help someone else with those same errors. So this is the first post in that "series" if I decide to go that route.

# The Program

This program is fairly simple as I'm practicing mostly syntax and rudimentary principals. I simply want to make a Celcius to Fahrenheit conversion script. Seems simple enough.

*Here was my first attempt of just coding without stopping*

```rust
fn main() {
    let x = temp_conversion(101.0, 'F');
    println!("The result from convert is: {}", x);
}

fn temp_conversion(temp: f64, metric: char) -> f64 {

    let result: f64 = temp;

    println!("Metric is: {}", metric);

    if metric == 'F' {
        let result = (result - 32.0) / 1.8;
    } else if metric == 'C' {
        let result = (result * 1.8) + 32.0;
    }

    result
}
```

There is an extremely huge mistake in this code though. While it _looks_ like it's going to work, it won't, giving me an error similar to this:

```bash
   Compiling temperature v0.1.0 (file:///Users/jd/code/rust/temperature)
warning: unused variable: `result`
  --> src/main.rs:13:13
   |
13 |         let result = (result - 32.0) / 1.8;
   |             ^^^^^^
   |
   = note: #[warn(unused_variables)] on by default

warning: unused variable: `result`
  --> src/main.rs:15:13
   |
15 |         let result = (result * 1.8) + 32.0;
   |             ^^^^^^

    Finished dev [unoptimized + debuginfo] target(s) in 0.55 secs
     Running `target/debug/temperature`
Metric is: F
The result from convert is: 101
```

You can see a couple problems.
- There is an unused variable warning in the compiler
- The code doesn't make any calculation

# Walkthrough

Lets go through line by line.

First I declare the main function, `fn main()`, which runs when you run `cargo run`. Inside of the main function I'm calling the `temp_conversion` function and assigning the output to variable `x`, then I'm simply printing that variable.

In `fn temp_converstion()`, I declare my parameters and their alotted type. `temp` is a 64 bit float or `f64` and then a `char` which is the metric parameter so I know what to convert from. The next thing you see is `-> f64` which is simply stating, "My output is going to be a 64 bit float."

I then move down to declare a variable called `result` which is _borrowing_ the value of temp. Again the type declaration is in there. Just so I can see what's happening in the log, I'm printing metric to the console.

The next step is to have a conditional to determine which formula to run, an `F` formula or a `C` formula. Inside of those two conditional blocks `result` is attempting to be shadowed with an updated value that eventually gets returned on the very last line of the function.

# So What's the Problem?

While this looks like it'll work, the compiler has other opinions. I reached out on the #rust-beginners IRC in order to find out. The people there were really helpful.

My first big mistake was that `result` isn't mutable. By default variables are _immutable_ meaning they can't change. You must explicitly state whether or not you want a variable to be able to change. so it looks like, `let mut result: f64 = temp;`.

The second mistake was my use of shadowing. In Rust, you only use the `let` keyword when you're declaring a new variable, not referencing an old one to mutate it's value. So I simply remove the `let` from the lines inside of the conditional blocks.

# Final Iteration

At the end my code looked like this:

```rust
fn main() {
    let x = temp_conversion(101.0, 'F');
    println!("The result from convert is: {}", x);
}

fn temp_conversion(temp: f64, metric: char) -> f64 {

    let mut result: f64 = temp;

    println!("Metric is: {}", metric);

    if metric == 'F' {
        result = (result - 32.0) / 1.8;
    } else if metric == 'C' {
        result = (result * 1.8) + 32.0;
    }

    result
}
```

And it works!

# Final thoughts

It's important to note, that this was a very rough implementation that doesn't count for many (if any at all) edge cases. I would have been better off using a `match` instead of `if/else` but that was it. I learned a few things from it anyway.

Rust is really interesting so far and learning about memory management and it's ownership system has to be one of the most interesting things I've studied in my short programming career.
