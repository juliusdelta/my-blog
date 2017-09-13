---
title: Parsing Arguments in Rake Tasks
layout: page
date: 2017-09-08 01:10:35
tags: ruby
---

I'm currently working as a Quality Assurance Engineer at a company called [Modern Message](https://modernmsg.com). Automating tests via an external service for VMs is something sorely needed. In the midst of configuring the automated test suite I figured out a good way to parse arguments given to rake tasks so I can test on whatever VM easily.

_If you want to quickly jump down to the good stuff scroll to OptionParser or The Use Case_

## Quick Context

I'm using [Rspec](https://rspec.info) to write these automated tests and wanted to find a way to get them to run with certain configurables via Rake tasks. I spent a few hours looking at different options. At a certain point I think I even considered using Thor. Why? Well the automated tests have an almost endless amount of options. Changing a hash, `.yml`, or `.json` everytime I wanted to test a different configuration didn't seem appealing to me. Nor did it seem sustainable for the future. The configuration hash I need to set looks like this:
``` ruby
options = {
'os' => 'OS X',
'version' => 'Sierra',
'browser' => 'Chrome',
'browser_version' => '60',
'resolution' => '1024x768'
}
```

This is only a small part of a larger hash with _more_ options. So navigating all those options in a sustainable, easily reproducible way was important.

## Enter Rake Args

Rake has support for arguments, but they aren't pretty or easily managable. There's 4 ways: The Rake Way, Environment Variables, ARGV, and OptionParser.

I used OptionParser. I won't go into too much detail, but the other three just aren't as easily managable or elegant. ARGV is simply an array, so you have to enter args in a specific order, and you have to keep that order in mind when adjusting your task. The Rake Way is just too weird to handle, especially cause zsh doesn't like it. Environment variables are just a pain, especially when you have as many as I already have to deal with. So lets talk about OptionParser.

## OptionParser

[OptionParser](https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html) is part of Ruby standard library as of `2.1.0` I believe. It allows you to easily parse through command line arguments when running a file or a Rake task. 

### Quick Example

```ruby
## hello.rb

require 'optparse'

options = { name: "World" }

o = OptionParser.new
o.banner = "Useage: ruby hello.rb [options]"
o.on(-n NAME, --name NAME) { |name| options[:name] = name }

args = o.order!(ARGV) {}

o.parse!(args)

puts "Hello #{options[:name]}"
```

```
$ ruby hello.rb -n Jonathan

#=> "Hello Jonathan"
```

See how simple that is? There's a few more nuances I had to figure out in my specific scenario, but it's mostly the same. Lets take a look at that.

## The Use Case

First I had to set up a rake task, and some default options so if no arguments are passed, tests are run on a "default" configuration.

```ruby
require 'rspec/core/rake_task'
require 'optparse'
require 'pp'

RSpec::Core::RakeTask.new(:single) do |t|

  options = {
    'os' => 'OS X',
    'version' => 'Sierra',
    'browser' => Chrome,
    'browser_version' => '60',
    'resolution' => '1024x768'
  }
  
  ... 
end
```

Next I had to set my options the right way. The banner you see there allows you to run `rake test single -- --help` in order to get the usage and argument list. This can be made pretty robust if needed.

```ruby
...
  o = OptionParser.new

  o.banner = 'Usage: rake test single [options]'
  o.on('-o OS', '--os OS') { |os| options['os'] = os }
  o.on('-v VERSION', '--version VERSION') { |version| options['version'] = version }
  o.on('-b BROWSER', '--browser BROWSER') { |browser| options['browser'] = browser }
  o.on('-s BROWSER_VERSION', '--browserversion BROWSER_VERSION') { |browser_version| options['browser_version'] = browser_version.to_s }
  ...
end
```

When you call `o.on` you pass in your agruments for what you want the flags to be, then you pass that to a lambda which will perform what ever action you choose with the given argument. I had to use `-s` for browser_version cause I lost creativity and it only works with one letter.

Finally I just cleaned up the args and converted it to a string using `.inspect`. You can also see I went ahead and printed options to the console so you could see what you did when you run the test.

```ruby
  args = o.order!(ARGV) {}

  o.parse!(args)

  puts "Your options are: "
  pp options

  ENV['CONFIG_SET'] ||= options.inspect
```

I used `.inspect` to turn the `options` hash into a `String` since environment variables can only be strings, as far as I can tell anyway. Once it is set, it's thrown into my main configuration hash in a `spec_helper` file to be used by the specs. Once in there I call `eval(ENV['CONFIG_SET'])` to convert it back into a hash. This _only_ works if the items in the original Hash values were Strings or Symbols. If they were custom objects then it won't work.

## Conclusion

After some more tweaking to my test suite I can run `rake test single -- -v Mavericks -b Chrome -s 59` to run the spec with a specfic confugration. You have to pass an empty arg in order to satisfy Rake, which is why there's a seemingly random `--` between `single` and the first arugment.

Cheers.
