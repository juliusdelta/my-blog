---
title: "Rails Heuristics - Validations"
author: ["JD"]
date: 2024-12-18
draft: true
ShowToc: true
TocOpen: true
---

> This is part 1 of a series about applying knowledge of Rails too an application via a few heuristics that I've found helpful.
>
> This guide is going to be based around Rails version 8, so if you're on an older version it's possible some of the APIs have changed or aren't available, however, validations haven't changed much so it's unlikely that will be the case. I'll ensure that I annotate the API if I find anything contrary to that.

Model validations in Rails can become untenable very quickly in some circumstances. A lot of this can be solved with good model design, however, sometimes it's unavoidable for them to become complicated. There's a few general heuristics I've begun to follow over the past year to make the validations I write more testable, maintainable, and understandable. The [Rails guide on validations](https://guides.rubyonrails.org/active_record_validations.html#custom-validators) is exceptionally informative, however, the purpose of the guides isn't to supply "guidelines" to follow for creating and testing validations, but instead it's intended to provide examples and explanations of available methods to accomplish a goal.

These examples are completely arbitrary, however, I've tried to make each of them meet a complexity threshold in order for the heuristic I recommend make sense.


## Responsibility of Validations {#responsibility-of-validations}

Validations provide the mechanism to control and implement _policies_ for your data/models. If you're keen, a lot of your business logic can be siphoned away into various types of validations which allows your controllers or other types of objects to simply worry about catching and dealing with errors as opposed to testing several predicates themselves before calling `.save`. Policy objects as a concept exists to provide an expressive way to house a complex predicate conglomerate in order to decide to take one action or another. Since they're standalone objects, they're generally easier to test and maintain long term as well as re-use in different contexts as long as the subject object has the same attributes. Rails validations serve the same purpose as Policy Objects, while not _only_ ever being relegated to an object.

Deciding the role that validations should play in your application or on a specific feature will largely be influenced by a given domain, however, there are a few things that clearly <span class="underline">should</span> be in the realm of validations. Since validations are all about policy requirements for attributes, their behavior should only be employed when the given policies themselves are static and don't change.

```ruby
# bad
account.update(email: email) if URI::MailTo::EMAIL_REGEXP.matches? email

# good
validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}

# bad
validate -> { Current.user.admin? }

# good
account.update(status: status) if Current.user.admin?
```


## Example {#example}

Sometimes you have multiple predicates by which you want a validation to be run. The most direct approach would usually be to use a `Proc` inline like:

```ruby
validates :price, presence: true, if: -> { tax_status.exists? && product.sellable?  }
```

More often than not though `tax_status.exists? && product.sellable?` represents a **policy** that would likely show up in other places of the app, at which point extracting to a predicate method makes for consistent design:

```ruby
# app/models/product.rb

validates :price, presence: true, if: :priceable?

# ...

def priceable?
  tax_status.exists? && product.sellable?
end
```

Lets arbitrarily expand this example a bit to illustrate an additional heuristic to consider. Say we need to validate the `price` amount. If the `price` is greater than `400` than we need to make sure tax can be applied and that the account owner has filled out the required tax forms. However, if the account owner has a `nonprofit` `tax_status` than we should allow any price up to an upper threshold of `5000` but not above. In this case we can use a method:

```ruby
validates :meets_pricing_thresholds?

# ...

def meets_pricing_thresholds?
  unless price < 400 && (account.tax_status == :nonprofit && price <= 5000 || price >= 400 && account.tax_approved?)
    errors.add(:price, "price must meet required thresholds for your account")
  end
end
```

This certainly works, and if your confident this _will never_ change than it's a perfectly acceptable solution. One simplification we can add would be to provide a _name_ to all the actual conditions that make up the `pricing_threshold`. In which case it would be something like this:

```ruby
validates :pricing_thresholds_met?

# ...

def pricing_thresholds_met?
  unless !taxable_minimum_threshold_met? && (non_profit_threshold_met? || taxable_status_threshold_met?)
    errors.add(:price, "price must meet required thresholds for your account")
  end
end

def taxable_minimum_threshold_met?
  price < 400
end

def non_profit_threshold_met?
  account.tax_status == :nonprofit && price <= 5000
end

def taxable_status_threshold_met?
  price >= 400 && account.tax_approved?
end
```

There's a code smell in OOP to watch out for that's when a number of methods use the same word than maybe there's an object that can be extracted from it. While I don't think OOP is always 100% prescriptive for everything, I think there's something valid to that here. The words `thresholds_met` seems to indicate there's a concept of a `PricingThreshold` that should exist explicitly. In order to preserve the focus on validations, lets just look at that concept implemented within the context of validations.

The final heuristic is to extract a validations to a Validator Object when multiple predicates &amp; branching requirements occur. Usually that threshold (pun intended), for me, is 3 predicates. The OOP argument for this is that "since it's a concept that obviously exists and should be given a proper realm of responsibility", but the _more important_ argument is, it's significantly more testable, readable, and maintainable long term.

First we'll just extract that validator

```ruby
# app/models/product.rb
validates_with PricingThresholdValidator

# app/validators/pricing_threshold_validator
class PricingThresholdValidator < ActiveModel::Validator
  def validate(record)
    unless taxable_minimum_threshold_met?(record) && (non_profit_threshold_met?(record) || taxable_status_threshold_met?(record))
      record.errors.add(:price, "price must meet required thresholds for your account")
    end
  end

  def taxable_minimum_threshold_met?(record)
    record.price < 400
  end

  def non_profit_threshold_met?(record)
    record.account.tax_status == :nonprofit && record.price <= 5000
  end

  def taxable_status_threshold_met?(record)
    record.price >= 400 && record.account.tax_approved?
  end
end
```

Already we can see how this is easier to reason about, but it also gives us the chance to write tests for this validation:

```ruby
class PricingValidatorTest < ActiveSupport::TestCase
  class MockedClass
    include ActiveModel::API

    attr_accessor :price, :account

    validates_with PricingValidator
  end

  def test_taxable_minimum_threshold
    subject = MockedClass.new(price: 399, account: OpenStruct.new(tax_status: :retail, tax_approved?: true))

    assert subject.valid?
    assert subject.errors.empty

    subject.price = 401
    subject.account.tax_approved? = false

    refute subject.valid?
    assert_includes subject.errors.full_messages, "price must meet required thresholds for your account"
  end

  def test_nonprofit_threshold
    subject = MockedClass.new(price: 4999, account: OpenStruct.new(tax_status: :nonprofit, tax_approved?: false))

    assert subject.valid?
    assert subject.errors.empty

    subject.price = 5001

    refute subject.valid?
    assert_includes subject.errors.full_messages, "price must meet required thresholds for your account"
  end

  def test_taxable_status_treshold
    subject = MockedClass.new(price: 401, account: OpenStruct.new(tax_status: :retail, tax_approved?: true))

    assert subject.valid?
    assert subject.errors.empty

    subject.account.tax_approved? = false

    refute subject.valid?
    assert_includes subject.errors.full_messages, "price must meet required thresholds for your account"
  end
end
```

Now that we have tests we can easily refactor to supply a more specific error message _based_ on the specific threshold

```ruby
class PricingThresholdValidator < ActiveModel::Validator
  def validate(record)
    if minimum_taxable_threshold_met?(record)
      validate_non_profit_threshold_met?(record)
      validate_taxable_status_threshold_met?(record)
    end
  end

  def non_profit_threshold_met?(record)
    unless record.account.tax_status != :nonprofit && record.price <= 5000
      record.errors.add(:price, "price exceeds maximum non-profit threshold.Amount must be less than 5000")
    end
  end

  def taxable_status_threshold_met?(record)
    unless record.account.tax_status == :nonprofit && record.account.tax_approved?
      record.errors.add(:price, "account tax policy is required before setting price")
    end
  end

  def minimum_taxable_threshold_met?(record)
    record.price > 400
  end
end
```
