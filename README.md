# Cooking Assistant

This is our project for a fully offline cooking app. No internet needed, ever. The whole point is helping someone who doesn't really know how to cook figure out what to make, based on what ingredients they've got, how much time and energy they have, their culture, and any dietary restrictions. Then it actually walks them through making it instead of just dumping a recipe on them.

## What it does
- You give it your ingredients, time, energy level, cultural preference and any dietary restrictions
- It filters and ranks dishes that fit what you gave it
- You pick a dish and go into the Interactive Virtual Kitchen, which walks you through cooking it step by step with simple visuals, made for someone with zero cooking experience
- You can view recipes in three modes: Silent, Normal, or Interactive
- You can save/favorite any recipe for later, no restrictions there

## Free vs Premium
No login, no payment system, it's all local. Freemium is the default when you open the app. Premium is unlocked with a redeem code entered on the device, nothing external.

- Freemium: limited number of dish recommendation requests per day, and the Interactive Virtual Kitchen only works on a small set of starter recipes
- Premium: unlimited requests, full Virtual Kitchen access on every recipe

## Built with
- Flutter (Dart) for the app itself
- Dart for the backend logic
- SQLite for the local database, since it's offline there's no server

## Who's doing what
- Dexter - backend lead, database structure, the algorithm that matches recipes to ingredients, CRUD stuff
- Tebong - Interactive Virtual Kitchen module, step-by-step walkthrough logic, handles the free/premium limit logic
- Ogechi - testing everything, making sure it works offline, handles the build
- Trendy - requirements, the rules for matching/free-premium, seed data for recipes and ingredients

## Status
Done, already built.

## How we're working
Everyone works on their own part first. Once done, we come together and go through each other's parts so everyone understands how it all fits. Then everyone pushes their part to GitHub on their own branch, based on what was assigned to them.
