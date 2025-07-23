---
title: "React Component Composition"
author: ["JD"]
date: 2025-03-20
tags: ["react", "component design", "javascript"]
categories: ["react"]
draft: true
description: "Favor composition in React."
ShowToc: true
TocOpen: true
---

For the past 7 1/2 years I've been working with React and the broader JS ecosystem. React itself is simply a UI library, not a framework. This means that React is extremely _unopinionated_ in how you use it. It's opinionated in a few other ways when it comes to things like data fetching, hooks/side effects, and rendering optimizations, but all in all, there are very **few** conventions inside of the React community.

There are meta-frameworks like React Router v7, NextJS, and Tanstack Start but these provide conventions in terms of how content is routed and served as opposed to how you actually design your components. They're one "meta layer up" above the component concern. 

Component design is overlooked as a skill from what I've seen in various online forums, companies I've worked at, projects I've seen, and even content from creators. This post (or maybe series?) is meant to serve as a catalog of what I've learned about high quality component design. I'm not a complete giga chad at this, but I do feel like in my 3/4 of a decade working with this tool, I've come up with a few heuristics that are useful.

## Classifications of Domain Layers
Before we dive into composition there's an important concept to understand concerning code design. When we think about the structure of application software we usually have several sets of classifications at each "layer" of an application. For instance, at the most foundational layer we may have a classification set of: database, business logic/backend, and UI/frontend. Then moving into each of those smaller pieces we use a different classifcation set. Diving into the business logic/backend classification, there are a few "sub-classifications" we can begin to deliniate. 

### Foundations & Implementors

The business logic/backend might be split into classifications such as the foundational models of the different business domains and then "implementors" of those models, sometimes classified as services or other types of objects representing an aggregate of those models. Implementors provide unique behavior for a particular action an end-user might take or a cron-job that periodically runs. One very important thing about implementors is that they act as "users of the foundational models." This means that there is an invisible **boundary** there that's important to consider when building both layers of the code.

The purpose of code design is to distinguish between the boundaries of those entities and determine responsibilities of each "layer" within that particular abstraction. When those boundaries are crossed, this is typically called a **leaky abstraction**. A leaky abstraction frequently results in code that's harder to maintain.

### Leaky Abstractions

One tell-tale sign of a leaky abstraction is when a model is modified in order to serve a specific purpose inside of the service layer. This is crossing the boundary and forcing code on both sides to care about a layer in which they wouldn't normally operate and shouldn't care about. The service becomes concerned with something _in_ model instead of model behavior, and the model now has to provide additional "out-of-scope" context in order for the service to accomiplish its job.

`ex-1` will provide an example of this to some degree but first lets talk about composition vs. inheritence.

## Composition > Inheritence

Both composition and inheritence are strategies for structuring code that works together to serve a particular purpose. Most developers hear at some point in their career to favor composition over inheritence. But what are they? and more importantly, _why_ should I favor composition?

### Inheritence

In Object Oriented Programming inheritence is seen as a domain model 

## Composition > Inheritence
There's a general concept in Object Oriented Programming that more often than not, composibility is favored over inheritence. This is not a hard and fast rule to follow 100% of the time, but it's a useful way to think about object design. It allows us to bring little pieces together _omakase_ style, without committing to having to use an entire other structure or domain that's irrelevant to a working context.

Lets look at a really simple example in Ruby.

> I picked ruby here because it's famously easy to read and parse out, even if you've never seen it before. 

```ruby
# Inheritence
class Character
  def attack
    raise NotImplementedError
  end
end

class Warrior < Character
  def attack
    return "Swings a great two-handed sword!"
  end
end

class Wizard < Character
  def attack
    return "Casts Fireball!"
  end
end
```

This structure works if this is the end of the domain evolution and no more features will be added. However, it quickly becomes rigid when new behavior is required. For instance if our `Wizard` needed a way to `enchant` an area around them. In that case, a `Wizard` isn't _just_ exhibiting `Character` behavior, but entirely _separate_ and unique behavior. At this small scale it doesn't seem like much, but eventually some where else in the code you're going to have write the following:

```ruby
if player.character.is_a? Wizard
  player.character.enchant
end
```

You may even get the "clever" idea to do this:
```ruby
class Character
  # ... previous code
  def can_enchant?
    false
  end
end

class Wizard
  # ...previous code
  def can_enchant?
    true
  end
end

player.character.enchant if player.character.can_enchant?
```

I've actually written code like this myself a lot in my career. This type of control flow may appear innocent enought at first, but is usually the knife that causes a death by a thousand cuts over time. It's not just the control flow, but it's also child class details leaking up to the super class, which sort of diminishes the point of the heirarchy itself.

Lets redesign this a bit with composition in mind.

```ruby
class Ability
  def perform
    raise NotImplementedError
  end
end

class SwordAttack < Ability
  def self.perform
    return "Swings a great two-handed sword!"
  end
end

class FireballAttack < Ability
  def self.perform
    return "Casts Fireball!"
  end
end

class EnchantGround < Ability
  def self.perform
    return "The ground is enchanted with magical energy!"
  end
end

class Character
  def initialize(abilities)
    @abilities = abilities
  end
end

class Wizard < Character
  def attack
    abilities['attack'].perform
  end

  def enchant
    abilities['enchant'].perform
  end
end

class Warrior < Character
  def attack
    abilities['attack'].perform
  end
end

wizard = Wizard.new({attack: FireballAttack, enchant: EnchantGround})
warrior = Warrior.new({attack: SwordAttack})
```

What's revealed in this example is that now it's left up to the implementor to decide what abilities a character has instead of being up to a concrete class. The `Ability`s are now being composed together in a way that leaves them closed to modification but open to extension. Need to add a new `Character` class? Just create the new class like `Sorcerer` and then create `Ability`s it can use. It may even be able to exhibit `FireballAttack` but also have a `secondary_attack` instead of just `attack`. 

The domain at this level doesn't care much about the domain level at which these objects are instantiated, the implementor cares about that. However, it's important to know: **The implementor always cares, but what they care about is going to be determined on your design now, at this domain level.** Do we want them to care about control flow and conditional logic? Or do we want them to care about the extension they're building?

When people discuss the concept of separation of concerns, they often leave out that sometimes those concerns are entire domain layers. In the first example, this "lower layer" had to compensate for it's poor design by writing a predicate method, `can_enchant?`, for the domain layer higher up to perform it's function ergonomically. It was a leaky concern.

So what does this mean for React component design?

### Composition in React

Lets start with a similar example, except more UI focused. 

```tsx
function Card(props) {
  return (
    <div className="flex flex-row" onClick={onClick}>
      <div className="flex flex-col">
        <h1>{props.title}</h1>
        <h3>{props.title}</h3>
      </div>
      <Image size={props.size} rounded={props.rounded} url={props.imageUrl} />
    <div>
  )
}

function Image(props) {
  // Ideally this would be a map of some kind or just tailwind stuff.
  const size = props.size == 'lg' ? '72px' : props.size == 'md' ? '58px' : '36px'
 
  return (
    <div className=`flex ${props.rounded ? 'rounded-full' : 'rounded-md' } ${size}`>
      <img src={props.imageUrl} />
    </div>
  )
}
```

This may not seem terrible at first but say a requirement comes in, and you need a `Card` with the same information but without the `Image`. Now you have a choice to make:

1. You add a "flag prop"
```tsx
function Card(props) {
  return (
    // ...previous code
    {props.showImage ? <Image size={props.size} rounded={props.rounded} url={props.imageUrl} /> : null}
    // ...previous code
  )
}
```

2. Or you just simply look if the `imageUrl` prop exists or not instead...
```tsx
function Card(props) {
  return (
    // ...previous code
    {props.imageUrl ? <Image size={props.size} rounded={props.rounded} url={props.imageUrl} /> : null}
    // ...previous code
  )
}
```

Now hang on. Say an developer (implementor) just finished implementing the "non-Image" version of the `Card` component somewhere else and now they have to create one with an `Image`. They may not realize that passing in just `imageUrl` **isn't enough**. An exception will be raised because `props.rounded` and `props.size` are `undefined`. Now the implementor is **forced** to care about the implementation details of `Card` when they shouldn't have to. 

Again, it's a violating the boundaries of domain layers and you're forcing an implementor to journey into the "base UI layer" instead of allowing them to work in a single domain.

So what's the solution here? (spoiler alert: it's composition)

### Composition Techniques

#### Forget the Props
Lets refactor the `Card` component to be composible

```tsx
function Card(props) {
  
  return (
    <div className="flex flex-row" onClick={onClick}>
      {props.children}
    </div>
  )
}

function CardTitle(props) {
  return <h1>{props.children}</h1>
}

function CardDescription(props) {
  return <h3>{props.children}</h3>
}

function CardContent(props) {
  return (
    <div className="flex flex-col">
      {props.children}
    </div>
  )
}

Card.Content = CardContent
Card.Description = CardDescription
Card.Title = CardTitle

export default Card

// Same as previous
function Image(props) {
  // Ideally this would be a map of some kind or just tailwind stuff.
  const size = props.size == 'lg' ? '72px' : props.size == 'md' ? '58px' : '36px'
 
  return (
    <div className=`flex ${props.rounded ? 'rounded-full' : 'rounded-md' } ${size}`>
      <img src={props.imageUrl} />
    </div>
  )
}
```

> As with all trivial examples, this looks like overkill for the situation, but it's often _not_ in a real world application. 

Now we have a composed API for our `Card` component. Lets see an implementation:

```tsx
<Card>
  <Card.Content>
    <Card.Title>Way of Kings</Card.Title>
    <Card.Description>Journey before destination</Card.Description>
  </Card.Content>
  <Image imageUrl='https://sanderson.com/wok/iamge.jpg' size='md' rounded />
</Card>
```

Now what does the one without the `Image` look like?

```tsx
<Card>
  <Card.Content>
    <Card.Title>Way of Kings</Card.Title>
    <Card.Description>Journey before destination</Card.Description>
  </Card.Content>
</Card>
```

Basically the same, with one line removed. Now implementors of our `Card` component aren't dealing with "flag props" in order to dictate the lower level component behavior, but instead pick "omakase" style excactly the functionality they require. Not only is this a more flexible API with what's provided, but _special cases_ get to be isolated in their "special domain". Lets say we wanted to use a `Card` that had 2 rows of icons in the middle of it for some reason. Here's what that would look like:

```tsx
<Card>
  <Card.Content>
    <div className="flex flex-row">
      {...generateIconsSet('primary')}
      {...generateIconsSet('secondary')}
    </div>
  </Card.Content>
</Card>
```

The flexibility is there for special cases because everything is the sum of it's tiny pieces instead of configurable blocks of functionality.

#### Shared UI 'State'

There are plenty of situations where you need to render something different depending on a "base level" state attribute, like a `disabled` state. With our previous pattern, in order to implement a disabled card, you'd have to create a `disabled` prop at every level. In our case, it would be the `Card.Title`, `Card.Description`, & `Image` components. There is a key API in React for this very purpose and can elevate what you can do with composition in this context (pun intended).

`React.createContext` is the perfect choice for creating a shared UI state among a very specific and tightly bounded domain, which in this case is our `Card` component.

> I'm not a fan of global stores and think that in most cases, they are absolutely not needed. In most cases where they'd be required I'd reach for event emitters > redux and keep their use to a minimum. A toast or notification bar might be the only place that is worth that trouble IMO.

Lets implement disabled and hover states for our component so the styles can change when either one of those things is true. We'll have to make one tiny modification to our top level API, but we'll extend it instead of breaking it.

```tsx
const CardContext = React.createContext({ hovered: false, dislabed: false })
const useCardContext = useContext(CardContext)

function Card(props) {
  <CardContext.Provider disabled={props.disabled} hovered={props.hovered}>
    <CardBase>
      {props.children}
    </CardBase>
  </CardContext.Provider>
}

// Completely private component to just wrap what's inside the `Card`
function CardBase(props) {
  const { disabled, hovered } = useCardContext()

  return (
    <div className=`flex flex-row ${hovered ? 'bg-gray-300' : 'bg-gray-800'}` disabled={disabled} onClick={onClick}>
      {props.children}
    </div>
  )
}

function CardTitle(props) {
  const { disabled } = useCardContext() 

  return <h1>{props.children} {disabled ? (<span>Unavailable</span>) : null}</h1>
}

function CardDescription(props) {
  const { disabled } = useCardContext()

  return <h3 className=`${disabled ? 'text-gray-300' : 'text-gray-800'}`>{props.children}</h3>
}

function CardContent(props) {
  return (
    <div className="flex flex-col">
      {props.children}
    </div>
  )
}

Card.Content = CardContent
Card.Description = CardDescription
Card.Title = CardTitle

export default Card
```

What's great here is that now the implementors don't have to be concerned about what the `Card` pieces have to do, they just have to pass the state to the top level component once in order to get the predefined behavior for free.

```tsx
// ...
const isDisabled = props.user.hasPermission(resource, action)

<Card disabled={isDisabled} hover={false}>
  <Card.Content>
    <Card.Title>Way of Kings</Card.Title>
    <Card.Description>Journey before destination</Card.Description>
  </Card.Content>
</Card>
```
