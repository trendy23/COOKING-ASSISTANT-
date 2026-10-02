-- Seed data for Cooking Assistant database (SQLite)

-- CULTURES
INSERT INTO cultures (id, name, region) VALUES
(1, 'Cameroonian', 'Central Africa'),
(2, 'Nigerian', 'West Africa'),
(3, 'Italian', 'Europe'),
(4, 'Chinese', 'Asia'),
(5, 'Mexican', 'Latin America');

-- CATEGORIES
INSERT INTO categories (id, name) VALUES
(1, 'Breakfast'),
(2, 'Lunch'),
(3, 'Dinner'),
(4, 'Snack'),
(5, 'Dessert');

-- INGREDIENTS
INSERT INTO ingredients (id, name, default_unit) VALUES
(1, 'Rice', 'g'),
(2, 'Plantain', 'piece'),
(3, 'Tomato', 'piece'),
(4, 'Onion', 'piece'),
(5, 'Garlic', 'clove'),
(6, 'Ginger', 'g'),
(7, 'Red palm oil', 'ml'),
(8, 'Vegetable oil', 'ml'),
(9, 'Chicken', 'g'),
(10, 'Beef', 'g'),
(11, 'Fish (dried or fresh)', 'g'),
(12, 'Egg', 'piece'),
(13, 'Maggi/bouillon cube', 'piece'),
(14, 'Scotch bonnet pepper', 'piece'),
(15, 'Spaghetti', 'g'),
(16, 'Beans', 'g'),
(17, 'Flour', 'g'),
(18, 'Sugar', 'g'),
(19, 'Milk', 'ml'),
(20, 'Butter', 'g'),
(21, 'Soy sauce', 'ml'),
(22, 'Spring onion', 'piece'),
(23, 'Carrot', 'piece'),
(24, 'Cabbage', 'g'),
(25, 'Parmesan cheese', 'g'),
(26, 'Basil', 'g'),
(27, 'Olive oil', 'ml'),
(28, 'Tortilla', 'piece'),
(29, 'Lime', 'piece'),
(30, 'Cilantro', 'g'),
(31, 'Black pepper', 'g'),
(32, 'Salt', 'g'),
(33, 'Water', 'ml'),
(34, 'Bitter leaf', 'g'),
(35, 'Groundnuts (peanuts)', 'g'),
(36, 'Ground crayfish', 'g'),
(37, 'Red bell pepper', 'piece');

-- RECIPES
INSERT INTO recipes (id, name, culture_id, category_id, prep_time_minutes, energy_level, is_starter, instructions) VALUES
(1, 'Jollof Rice', 1, 3, 45, 'medium', 0, 'Blend tomato, red bell pepper, onion and scotch bonnet. Fry the blend in oil with garlic and ginger. Add rice, stock and maggi, cook until rice is soft and has absorbed the sauce.'),
(2, 'Fried Ripe Plantain', 1, 4, 15, 'low', 1, 'Slice ripe plantain diagonally, fry in hot oil until golden on both sides, drain and season lightly with salt.'),
(3, 'Ndole (Bitter Leaf and Peanut Stew)', 1, 3, 75, 'high', 0, 'Wash and boil the bitter leaf several times to remove bitterness. Blend groundnuts with onion, garlic and ginger into a paste. Boil the beef until tender, then combine with the groundnut paste, crayfish, palm oil and bitter leaf, and simmer until thickened.'),
(4, 'Nigerian Jollof Spaghetti', 2, 3, 35, 'medium', 0, 'Fry blended pepper mix, add spaghetti and stock, simmer until spaghetti absorbs the sauce.'),
(5, 'Egg Sauce', 2, 1, 15, 'low', 1, 'Fry onion, tomato and pepper, crack eggs directly in and scramble together, season.'),
(6, 'Fried Rice (West African style)', 2, 3, 40, 'medium', 0, 'Par-cook rice, saute chopped veg in oil, mix rice in, add soy sauce and seasoning.'),
(7, 'Spaghetti Aglio e Olio', 3, 3, 20, 'low', 0, 'Cook spaghetti. Gently fry garlic in olive oil until golden, toss spaghetti in, finish with black pepper.'),
(8, 'Simple Tomato Pasta', 3, 3, 25, 'low', 0, 'Cook pasta. Saute garlic and onion, add tomato, simmer into a sauce, toss pasta through, top with parmesan.'),
(9, 'Garlic Butter Egg Toast', 3, 1, 10, 'low', 1, 'Fry egg in garlic butter, serve over toasted bread, season with salt and pepper.'),
(10, 'Egg Fried Rice', 4, 3, 20, 'medium', 0, 'Scramble egg, set aside. Fry rice with soy sauce, spring onion and carrot, mix egg back in.'),
(11, 'Ginger Garlic Chicken Stir Fry', 4, 3, 30, 'medium', 0, 'Marinate chicken in soy, ginger and garlic. Stir fry with cabbage and carrot until chicken is cooked through.'),
(12, 'Simple Egg Drop Soup', 4, 2, 15, 'low', 0, 'Bring seasoned water/stock to a light boil, drizzle in beaten egg while stirring, finish with spring onion.'),
(13, 'Chicken Tacos', 5, 3, 30, 'medium', 0, 'Season and cook chicken, warm tortillas, assemble with onion, cilantro and lime.'),
(14, 'Simple Beef Tacos', 5, 3, 30, 'medium', 0, 'Brown beef with onion and garlic, season, serve in tortillas with lime and cilantro.'),
(15, 'Egg and Cheese Quesadilla', 5, 1, 15, 'low', 0, 'Scramble egg, place on tortilla with cheese, fold and toast in a dry pan until crisp.');

-- RECIPE_INGREDIENTS
INSERT INTO recipe_ingredients (recipe_id, ingredient_id, amount, unit, is_essential) VALUES
(1, 1, 300, 'g', 1), (1, 3, 3, 'piece', 1), (1, 37, 1, 'piece', 1), (1, 4, 1, 'piece', 1),
(1, 5, 2, 'clove', 1), (1, 6, 5, 'g', 0), (1, 14, 1, 'piece', 0), (1, 8, 30, 'ml', 1), (1, 13, 1, 'piece', 1),

(2, 2, 3, 'piece', 1), (2, 8, 100, 'ml', 1), (2, 32, 2, 'g', 0),

(3, 34, 200, 'g', 1), (3, 35, 150, 'g', 1), (3, 36, 30, 'g', 1), (3, 10, 300, 'g', 1),
(3, 4, 2, 'piece', 1), (3, 5, 3, 'clove', 1), (3, 6, 10, 'g', 1), (3, 7, 40, 'ml', 1),
(3, 14, 1, 'piece', 0), (3, 13, 1, 'piece', 1), (3, 32, 1, 'g', 0),

(4, 15, 250, 'g', 1), (4, 3, 2, 'piece', 1), (4, 4, 1, 'piece', 1),
(4, 14, 1, 'piece', 0), (4, 13, 1, 'piece', 1),

(5, 12, 3, 'piece', 1), (5, 3, 2, 'piece', 1), (5, 4, 1, 'piece', 1),
(5, 8, 15, 'ml', 1), (5, 13, 1, 'piece', 0),

(6, 1, 300, 'g', 1), (6, 23, 1, 'piece', 0), (6, 24, 100, 'g', 0),
(6, 21, 15, 'ml', 1), (6, 8, 20, 'ml', 1),

(7, 15, 200, 'g', 1), (7, 5, 4, 'clove', 1), (7, 27, 40, 'ml', 1), (7, 31, 2, 'g', 0),

(8, 15, 200, 'g', 1), (8, 3, 4, 'piece', 1), (8, 4, 1, 'piece', 1),
(8, 5, 2, 'clove', 0), (8, 25, 20, 'g', 0),

(9, 12, 2, 'piece', 1), (9, 20, 15, 'g', 1), (9, 5, 1, 'clove', 0),

(10, 1, 300, 'g', 1), (10, 12, 2, 'piece', 1), (10, 21, 15, 'ml', 1),
(10, 22, 1, 'piece', 0), (10, 23, 1, 'piece', 0),

(11, 9, 300, 'g', 1), (11, 6, 10, 'g', 1), (11, 5, 2, 'clove', 1),
(11, 24, 100, 'g', 0), (11, 21, 15, 'ml', 1),

(12, 33, 500, 'ml', 1), (12, 12, 2, 'piece', 1), (12, 13, 1, 'piece', 1), (12, 22, 1, 'piece', 0),

(13, 9, 300, 'g', 1), (13, 28, 4, 'piece', 1), (13, 4, 1, 'piece', 0),
(13, 30, 5, 'g', 0), (13, 29, 1, 'piece', 0),

(14, 10, 300, 'g', 1), (14, 28, 4, 'piece', 1), (14, 4, 1, 'piece', 1),
(14, 5, 1, 'clove', 0), (14, 29, 1, 'piece', 0),

(15, 12, 2, 'piece', 1), (15, 28, 2, 'piece', 1), (15, 25, 30, 'g', 1);

-- RECIPE_DIETARY_TAGS
INSERT INTO recipe_dietary_tags (recipe_id, tag) VALUES
(1, 'vegetarian'), (1, 'gluten_free'), (1, 'dairy_free'),
(2, 'vegan'), (2, 'vegetarian'), (2, 'gluten_free'), (2, 'dairy_free'), (2, 'nut_free'),
(3, 'gluten_free'), (3, 'dairy_free'), (3, 'no_pork'),
(4, 'vegetarian'), (4, 'dairy_free'),
(5, 'vegetarian'), (5, 'gluten_free'), (5, 'dairy_free'),
(6, 'vegetarian'), (6, 'gluten_free'), (6, 'dairy_free'),
(7, 'vegan'), (7, 'vegetarian'), (7, 'dairy_free'),
(8, 'vegetarian'),
(9, 'vegetarian'),
(10, 'vegetarian'), (10, 'gluten_free'), (10, 'dairy_free'),
(11, 'no_pork'), (11, 'dairy_free'),
(12, 'vegetarian'), (12, 'gluten_free'), (12, 'dairy_free'), (12, 'no_pork'),
(13, 'no_pork'), (13, 'dairy_free'),
(14, 'no_pork'), (14, 'dairy_free'),
(15, 'vegetarian');

-- REDEEM_CODES
INSERT INTO redeem_codes (id, code, is_used) VALUES
(1, 'COOK-PREMIUM-001', 0),
(2, 'COOK-PREMIUM-002', 0),
(3, 'COOK-PREMIUM-003', 0);
