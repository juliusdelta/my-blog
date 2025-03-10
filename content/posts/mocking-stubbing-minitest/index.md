---
title: "Mocking and Stubbing in Minitest"
author: ["JD"]
date: 2025-01-04
draft: true
ShowToc: true
TocOpen: true
---

Minitest stubbing and mocking can seem unnecessarily complicated at first, given how little `Object#stub` and `Mock#expect` appear to offer. I'm working on another post about _why_ I prefer Minitest over Rspec and the merits I think Minitest offers. While I love Minitest, I do think the documentation can be pretty minimal sometimes leaving you to figure out the _implications_ of the examples rather than providing more comprehensive examples of various patterns to follow.


## Boundaries {#boundaries}

The standard Minitest library is opinionated in that it doesn't offer a lot of ways to stub interactions. This limitation in Minitest requires you to think about the _bounds_ of the code and what objects are interacting with other objects.


## Overview {#overview}


### `Object#stub` {#object-stub}

`Object#stub` is a useful API to stub class methods or specific instance methods and return a specified value. It's intention is not to verify something was called (like `Mock#expect`) but instead to provide an "escape hatch" for unimportant details to the test your currently writing.


## Pragmatic Examples &amp; Patterns {#pragmatic-examples-and-patterns}


### Stubbing/Mocking Object Instantiation {#stubbing-mocking-object-instantiation}

Whenever you need to instantiate an object that isn't passed in as an argument ensuring the proper behavior or it's functions is difficult to do without writing an integration type test. We've ready discussed the importance of having good boundaries in your code and that stretches all the way to your tests. Sometimes Dependency Injection isn't the right call or doesn't fit, or you have some technical debt that is unavoidable and not changable at the current moment. How do you stub/mock this?

Here's an example where the `audit` method instantiates an `Entry` object. `Entry` will always be the class used here, so dependency injection doesn't really make sense unless you do it purely for your tests at this point in time:

```ruby
def audit(**kwargs)
  entry = Entry.new(**kwargs)

  raise unless entry.valid?

  entry.log!
end
```

This method doesn't really care about the `Entry` instance internals or behavior, just that it responds to `:valid?` and `log!`. The priority of the unit test for `audit` should just be that it:

-   Creates a new `Entry`
-   Raises if it's invalid
-   Calls `#log` on it

That's it. The boundary here ends at the methods we're calling on the `Entry` instance is all we care about. Here are tests written with that in mind:

```ruby
def test_audit_performs_log
  mock_entry = Minitest::Mock.new
  mock_entry.expect :valid?, true, []
  mock_entry.expect :log!, nil, []

  Entry.stub :new, mock_entry do
    audit some: :args
  end

  assert_mock mock_entry
end

def test_audit_raises_when_entry_invalid
  mock_entry = Minitest::Mock.new
  mock_entry.expect :valid?, false, []

  Entry.stub :new, mock_entry do
    assert_raises StandardError do
      audit some: :args
    end
  end

  assert_mock mock_entry
end
```

The test might seem small and insignificant, but if the `audit` method tries to have `Entry` instance behavior _added or removed_ from it this test will fail. We're enforcing the tight contract and boundary with this test and telling future developers that "The only thing this method is responsible for is calling `log!` on a valid `Entry` instance."

Sometimes, we'll need to test the arguments that are passed to `Entry.new` as well in which case it's a bit more complicated but still very explicit. If our `audit` method needs to perform some function on the `kwargs` passed in and then create a new entry we can handle this by mocking the **call** of `:new` instead of just handling the return value. This test is teetering on the line about testing too much, but I think the priority should be testing public methods and not private ones, so if the calculation is or should be private to whatever `Class` or `Module` `audit` lives in, than it should remain so. Here is a test that will cover this use case:

```ruby
def test_audit_performs_log
  mock_entry_new = Minitest.new
  mock_entry = Minitest::Mock.new

  mock_entry_new.expect :call, mock_entry, [], some: :val

  mock_entry.expect :valid?, true, []
  mock_entry.expect :log!, nil, []

  # `:new` is the method name and
  # `val_or_callable` arg is mocked to return the proper object
  # in this our mock_entry
  Entry.stub :new, mock_entry_new do
    audit some: :val
  end

  assert_mock mock_entry_new
  assert_mock mock_entry
end
```

Now, not only do we test that `audit` calls the correct methods on an `Entry` instance, but we're also confirming the arguments the `Entry` instance is created with, since it's private to `audit` it doesn't matter what that is to the world, but it matters what the result is!
