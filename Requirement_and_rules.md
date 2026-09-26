# Requirements & Rules : Cooking Assistant App

## 1. Cultures
- Cameroonian (id 1) — Central Africa
- Nigerian (id 2) — West Africa
- Italian (id 3) — Europe
- Chinese (id 4) — Asia
- Mexican (id 5) — Latin America

## 2. Recipe categories
Breakfast, Lunch, Dinner, Snack, Dessert

## 3. Dietary restriction tags
Hard filter : if a user selects one, any recipe with an essential ingredient that conflicts is excluded completely.
- vegetarian
- vegan
- no_pork
- gluten_free
- dairy_free
- nut_free

A recipe can have zero, one, or multiple tags.

## 4. Energy level
Soft preference. User selects Low, Medium, or High energy. Each recipe has an energy_level based on how much active effort it requires. A recipe matching the user's energy level scores higher but is not excluded if it doesn't match.

## 5. Matching and ranking rule
**Stage 1 — Hard filter: remove any recipe that conflicts with the user's selected dietary restriction(s).

**Stage 2 — Score and rank remaining recipes:**
```
score = ingredient_match * 60
      + time_fit * 20
      + culture_bonus * 10
      + energy_fit * 10
```
- ingredient_match = essential ingredients user has / total essential ingredients
- time_fit = 1 if recipe.prep_time_minutes <= user_time, else 0
- culture_bonus = 1 if recipe.culture_id matches user's selected culture, else 0.3
- energy_fit = 1 if recipe.energy_level matches user's selected energy, else 0.5

Recipes with a total score below 50 are not shown.

## 6. Display modes
- Silent : text/recipe only, no narration
- Normal : text with step highlighting
- Interactive : full Virtual Kitchen walkthrough with visuals, waits for user

## 7. Freemium vs Premium rules
- Freemium: capped at 7 dish recommendation requests per day.
- Freemium's Interactive Virtual Kitchen is limited to recipes flagged as starter recipes (is_starter = 1). All other recipes remain available in Silent/Normal mode.
- Premium: unlocked locally via a redeem code, no payment or server check involved. Unlimited requests, full Virtual Kitchen access on every recipe.
- Favoriting/saving recipes has no tier restriction.

## 8. Seed data summary
5 cultures, 5 categories, 33 ingredients, 15 recipes. Each recipe includes an energy level and a starter-recipe flag. Dietary tags and sample redeem codes are included for testing.
