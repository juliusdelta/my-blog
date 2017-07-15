---
title: Recursion is Your Friend, Till it isn't
date: 2017-04-12 09:52:06
layout: page
tags: recursion
---

I was fairly new to data structures when I had to implement a binary heap (tree) in Ruby. It was challenging for me to say the least, but what made it especially challenging was that I had a new found love for recursion. This is not an in depth tutorial on recursion or binary trees, but simply an example case of when/when not to use recursion to accomplish your task and how to weigh your options.

# Binary Tree
If you’re unfamiliar with a binary tree, I’ll do a quick explanation of what they are. It’s simply a data structure shaped like a tree. The root is the first item. That root has two children, a left and a right child. Each of those two children have their own left and right children and so forth.

There’s variations of a binary tree that implementing sorting. A *min-heap* is where the smallest item is the root and it’s in ascending order going down the tree. A *max-heap* is where the largest is at the top and goes down to the smallest. Usually these are sorted from left to right as well.

**Our example will be using a min heap.**

_Don’t Judge_

Being my first time, my solution wasn’t elegant by any means, but it worked for what I needed too. I had one method to organize the data, then another to organize what the left and right values would be. This can definitely be done all in one method, but like I said it was my first time, so don’t judge me.

# The Code
So first I had to start off by creating nodes that would be used as the individual sets of data. Each node had a title, rating, left, and right values. The test cases were movie titles and their rotten tomatoes ratings. They were sorted based on their rating.

Here’s my node.rb:
```ruby
class Node
  attr_accessor :title
  attr_accessor :rating
  attr_accessor :left
  attr_accessor :right
  def initialize(title, rating)
    @title = title
    @rating = rating
    @left = nil
    @right = nil
  end
end
````

It’s pretty straight forward. Now on to the hard part: implementing the heap.
The heap would ultimately be based off an array of nodes. Now, there’s a lot to be said about using an array data structure because of memory concerns, but I’ll address that in another post. For now, humor me.

# Insert

So I start off by initializing `@heap` with a new Array. Then on to my insert method. Now this insert method _does_ utilize recursion in a cool way (I think.) I simply add the node to be inserted into the end of the heap array no matter what. I then obtain my new item’s index by taking the length of heap and subtracting one. Next, I put in a simple check to see if there’s any other items in the array so far, if there is NOT, I simply make sure the left and right properties are set to `nil` and move on. If there is other items, I then call a recursive function called `bubble_up` which takes one argument, the new nodes index, and then it begins to work it’s magic.

# Bubble Up

This is where I used recursion the smart way. I take the new node and compare it to the parent. If the parent is less then the current index, the min heap is all good and we return out. If it’s the opposite, then it swaps the parent and the child. Then we repeat the process again with the new node at it’s new index (previously the parent index.) I repeat the process by calling it recursively until the parent of the new node is less than itself. Here’s the method:

```ruby
def bubble_up(index) 
  parent_index = get_parent(index) 
  if @heap[index].rating > @heap[parent_index].rating 
    return 
  elsif @heap[index].rating < @heap[parent_index].rating 
    temp = @heap[parent_index] 
    @heap[parent_index] = @heap[index] 
    @heap[index] = temp 
    self.bubble_up(parent_index) 
  end 
end
```

So we call bubble_up on the returned parent index to repeat the comparison process all over again.

# Call Stack
One important thing to keep in mind as you use recursion is the stack of processes to be resolved. In this case, that stack size is dependent upon what has already been sorted. The function never really “ends” until it returns out of itself or when the parent is less than the child. This is a minor detail right now, and is ok in this scenario, but moving on you’ll see why it can lead to bad things.

# Set Left & Right
The next thing to be done was to set the left and right values of each node starting at a particular index. It takes the index[0] and calls two methods, get_left_child and get_right_child in order to get the location in the array of where the children should be. It then goes to the next item in the array, and does the same thing.

> Ex: [1, 2, 3, 4, 5] It calculates that 2 is the left child of 1, and 3 is the right child of 1. It then moves on to 2 and calculates the children should be 4 & 5 etc…

This is where I implemented recursion poorly. The method does not fully resolve, until left_child == nil or right_child == nil which may not seem like a big deal, but think of an example of an array with 30 items. When it goes through the first iteration it holds all of those variables, method calls, and values in memory, then it recursively calls itself, holding double that amount for the second iteration. Then it adds another set for the third, another for the fourth etc... So by the end of the stack, we’ll have 30 sets of iterations all being held in memory.

# This is bad.

It’s like 30 nested function calls all do do one thing. Here’s the awful recursive implementation.

```ruby
def set_left_right(index)
  left_child = get_left_child(index)
  right_child = get_right_child(index)
  unless @heap[left_child] == nil
    @heap[index].left = @heap[left_child]
  end
  unless @heap[right_child] == nil
    @heap[index].right = @heap[left_child]
  end
  until index == @heap.size — 1
    index += 1
    set_left_right(index)
  end
end
```

Needless to say, I ran some ruby benchmarks to work with an array of 10,000 nodes. I never even made it to 30, because it would simply take way too long. After 26 or so iterations, it would slow down and take 10–15 seconds for the next one, then for the 27th, that would double. Then for the 28th, THAT would double… It was bad.

# The Change
After speaking with my mentor on the subject and why my solution was so bad, I implemented an iterative solution. It would only have to be called once and not take any arguments. It would iterate over the entire array and set the correct left and right values. As a linear solution, it wasn’t terrible performance wise. Here’s the revised code:
```ruby
def set_left_right
  @heap.each_with_index do |x, index| 
    left_child = get_left_child(index)
    right_child = get_right_child(index)
    unless @heap[left_child] == nil
       @heap[index].left = @heap[left_child]
    end
   unless @heap[right_child] == nil
     @heap[index].right = @heap[left_child]
   end
  end
end
```

You see, my call stack stayed relatively shallow as I was just iterating through the array of nodes, and setting some values. I’m sure if I were to sit down and redo this assignment, I’d design it all much differently, but it did it’s job, and for my first time implementing something I felt was so complex, I was proud.

Always remember, when you’re trying to implement a recursive solution in something, it’ll cost you.

**If you have any questions or suggestions feel free to share.**
