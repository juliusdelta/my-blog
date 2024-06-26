---
title: "Thoughts on Interfaces for Models"
author: ["JD"]
date: 2021-02-11
tags: ["design", "architecture"]
categories: ["development"]
draft: false
description: "After making small changes to a model, it got me thinking hard about how I build interfaces."
ShowToc: true
TocOpen: true
---

I recently had to build an interesting model that stored values for a JWT in order to implement an allow list style revocation strategy. After some feedback from another developer it became clear the interface for that model needed to be optimized. Here's a quick description of the "behavior" of that model:

-   All of the columns are read only after creation
-   It's dependent on a `User` record assocation - thus requires a validation
-   It has an expiration time that is also stored, but set to a pre-determined amount of time
-   It's `jti` column value is generated by the model itself since it is a "propietary" action per record

Given this set of behavior we can infer that **since the `expires_at` column and `jti` are both self generated in the model code, the only attribute required for creation is the associated `User` record.**

This made the code for the model drastically simpler and also gave me constraints to artificially impose on the model itself, preventing updates and making attributes read only.

Rails provides a nifty way of doing these things but this principal can be used with any language/framework.

```ruby
# Model Class Example
class AllowListedToken < ApplicationRecord

  # ...
  attr_readonly :jti, :user_id, :expires_at # prevents update calls on these columns

  EXPIRATION_TIME = 1.day.from_now

  belongs_to :user

  ## after_initialize is called when the object is created but before the `INSERT` is called
  ## allowing for object transformations to take place before the record persists.
  after_initialize :set_generated_values

  # ...

  private

  def set_generated_values
    self.jti = JtiGenerator.new.jti
    self.expires_at = EXPIRATION_TIME
  end
end

# Usage
user = User.find(id)
AllowListedToken.create!(user: user)
```

The moral of the story is to take time to consider how your model should behave and what limitations or defaults you can implement to ensure that the constraints you need to fulfill are fulfilled. This helps ensure the maintainability and simplicity of the model and helps to align the expectated behavior and usage.
