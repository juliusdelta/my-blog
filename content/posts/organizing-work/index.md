---
title: "Organizing Work is Hard"
author: ["JD"]
date: 2019-11-27
tags: ["soft-skills"]
categories: ["career"]
draft: false
description: "Taking on organizational responsibility for other developers work is hard work in of itself. It is a careful balance of planning, architecture, and confidence."
ShowToc: true
TocOpen: true
---

As an engineering team grows it becomes imparitive that the leadership among that team grows to scale as well. We all know that organizing work on a product is difficult, but the organization of the engineering team specifically plays the most significant role in the overall developer experience. My personal experience up till this point has been to work mostly on projects or features either by myself or with a single other more senior developer. Over the last quarter I was given the temporary title of technical lead on a project with 4 other developers, which presented an extremely difficult learning opportunity for me.

My time as a developer has been marked by taking on research or projects on my own. I spent a good three months managing a set of contractors and then embarked on mostly solo projects. Organizing work for fully integrated team waa something completely foreign to me. This write up simply serves as a way to help solidfy some of what I learned and hopefully help other people in similar situations.


## Theorizing Architecture is a Skill {#theorizing-architecture-is-a-skill}

The project I undertook this quarter was not a large full stack architectural effort, instead, it focused mainly on the frontend (React) of our application. We try to be very intentional about how we build components and UI elements to ensure that what needs to be reusable, can be, and that larger page or template type components recieve a quality composition focused structure for easy maintenance. This meant that embarking on a greenfield feature, required some forethought on how the different component API's would work together and how we would handle the required data to accomplish the overall goal of what we wanted to build.

**Herein lies the challenge: coming up with an architectural plan and executing it over the course of weeks.**

In the past, my tendency was to always do "proof-of-concepts" that would more often than not, just turn into the code that would actually be used. I never really had to decide on something prior to writing anything and just hoped that it would work. Fairly early on in the project, I had the "birds eye view" of how this whole feature could work. I took my "birds eye view" solution and organized the work as such. Our sprints, stages of completion, and deadlines were all built around my rough solution and tickets were broken down and written to accomodate small units of that very idea.

This resulted in a large amount of insecurity in how I was leading the team. Why? I didn't really focus on building a complete, very thorough plan, I just maintained my own rough idea. Four developers working through a plan really puts to the test the quality of the plan and ultimately the experience those developers have while executing it. When areas came up that I had inevitably overlooked, we had to make pivots, or have short pairing sessions to help determine the most optimal solution to whatever it was. Pivots to some degree are inevitable in building software, however, these seemed very avoidable as if one or two more hours of thinking would have surfaced these gaps at the beginning.

This, at least in part, is what I think helps to define a good senior developer, who not only advocates for quality practices, but also for a good experience for all the developers working around them. Their ability to come up with a detailed plan, minimizing the risk of pivots during a project, and having a framework for dealing with those situations will ensure that the developers working along side them have the best experience possible. Great experiences like this, free up developers to come up with more innovative solutions or to collaborate more on an idea to make things better for the long term.

My biggest take away from this was to spend more time planning out how something was to be built do my best proving out examples of the more complex bits and pieces of the code to help deter unknowns.


## Define Success &amp; Failure Early {#define-success-and-failure-early}

I think there comes a point in a lot of software companies where data becomes a huge contributor to the products over all direction. Once a business establishes itself it begins the process of making everything better and understanding it's users is finer detail. This very quickly builds the case for proper and established baselines as features are developed. The project we worked on was not large, but it had strong potential to either damage our user conversion/retention rates or improve them. We failed to really understand this potential early on, and failed to understand what "failing", or "success" for that matter, means. This wasn't any one persons fault, it was just a gap the entire team contributed to.

It wasn't till about a month into the project that we began discussing a roll out plan. This lead to discussions of the "risks" involved in changing such a critical piece of our user experience. It was then that we began to dig into the data to try to understand that risk as much as possible. Getting to this point was a good thing and meant that the team was growing more mature, however, this realization came very late. It resulted in a fairly large pivot and a lot of time spent researching how to circumvent certain hurtles in the process.

Understanding risks, impacts, and how things will be measured early ensures that development goes smoothly and the smallest units of work shippable can be completed quickly, in a quick agile-esque cycle. This also helps to guide the later stages of a project and gives you a steady framework for adjusting to pivots that arise during the development of a feature.
