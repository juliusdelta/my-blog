---
title: "Double Polymorphic Associations in Rails"
author: ["JD"]
date: 2021-05-31
tags: ["rails", "programming"]
categories: ["development"]
draft: false
description: "A quick overview of using associations to define good domain descriptions as well as good behavior."
ShowToc: true
TocOpen: true
---

Polymorphic associations is a common theme among many applications. Things can get complicated, especially as far as naming is concerned, when you consider having a double polymorphic association. Rails provides all the necessary mechanisms by which to manage this in a way that makes sense for most business needs as well as leaving it readable for future programmers that come by in the future.

> In programming languages and type theory, polymorphism is the provision of a single interface to entities of different types or the use of a single symbol to represent multiple different types.

The example we'll work with today is one taken from some work I recently did helping to implement a Favorites feature. The requirements for this were:

-   A `User` can have many favorites, which can be a `Report` or a `Team`
-   A `Team` can have many favorites, which can be a `Report`

This is what I mean by a double polymorphic relationship. One side, _favoritor_, can be one of a `User` or `Team` while the other side, the _favouritee_, can be of the type `Team` or `Report`. The requirements lended itself to building a `Favoritings` table and using that as our base. This would have a `favoritor` and `favoritee` polymorphic columns, which with Rails and ActiveRecord automatically include the `id` and `type` of each of those. This is what the migration looked like:

```ruby
class CreateFavoritings < ActiveRecord::Migration[6.1]
  def change
    create_table(:favoritings) do |t|
      t.references(:favoritee, polymorphic: true, index: true)
      t.references(:favoritor, polymorphic: true, index: true)
      t.timestamps
    end
  end
end
```

So now comes time to develop the actual relationships to the other models. This is _complicated_ to a degree but you have to consider how your domain is laid out in order to define these relationships as they're needed. For one a Team can have many favourites and a User can have many favourites. Lets solve that first.

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :favorites, class_name: 'Favoriting', foreign_key: :favoritor_id, as: :favoritor
end
```

While the name of the relationship isn't exact to the model, the domain name of `favorites` makes total sense. A User has many favorites. We then go onto define what the class name is since we're not explicitely using the `Favoritings` class name. Then we have to tell it the key this relationship uses on that model, as well as the type. A `User` has many `favorites` of class `Favoritings` based on the foreign key `favoritor_id` as the type of `favoritor`. This makes a well understood API for querying later: `User.find(1).favourites` will yield all the favourites. You could also get more specific with:

```ruby
  has_many :favorite_teams, class_name: 'Favoriting', foreign_key: :favoritor_id, as: :favoritor, source_type: 'Team'
```

This not only defines the relationship more explicitely to the individual type but also builds the query via a join instead of having to call another query to scope it down after the fact. One of the many optimizations ActiveRecord can supply us.

Now lets implement the other side: `Teams` as a favoriting.

```ruby
# app/models/team.rb
class Team < ApplicationRecord
  has_many :favoritings, as: :favoritee
  has_many :user_favoritors, through: :favoritings, source: :favoritor, source_type: 'User'
end
```

The first relationship says a `Team` has many `favouritings` as the `favouritee`. So this model can be "favorited." Next we have a `Team` has many `user_favoritors` through `Favoritings` model which are of the type `Users` and the key/type is `favoritor`. This will pull all the users that have favorited this team. Just like earlier this allows ActiveRecord to optimize queries for these early on instead of running mulitple or having to manage scopes. This also provides a very readable API for developers down the road.

This is half the aforementioned implementation but it describes the principal enough. Rails and ApplicationRecord provides a great and flexible interface for explicitely defining these types of complex relationships that all flow through the same model.
