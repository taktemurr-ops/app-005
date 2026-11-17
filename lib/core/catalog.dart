import 'models.dart';
import 'nutrition.dart';

const standardMeals = ['breakfast', 'lunch', 'dinner', 'snack'];

List<Food> defaultFoods() => [
  const Food(id: 'apple', name: 'Apple / Elma', category: 'fruit', per100g: Nutrients(kcal: 52, protein: .3, carbohydrate: 13.8, fat: .2, fiber: 2.4)),
  const Food(id: 'banana', name: 'Banana / Muz', category: 'fruit', per100g: Nutrients(kcal: 89, protein: 1.1, carbohydrate: 22.8, fat: .3, fiber: 2.6)),
  const Food(id: 'oats', name: 'Oats / Yulaf', category: 'grain', per100g: Nutrients(kcal: 389, protein: 16.9, carbohydrate: 66.3, fat: 6.9, fiber: 10.6), servingGrams: 40),
  const Food(id: 'rice', name: 'Cooked rice / Pirinç pilavı', category: 'grain', per100g: Nutrients(kcal: 130, protein: 2.7, carbohydrate: 28.2, fat: .3, fiber: .4)),
  const Food(id: 'bread', name: 'Wholegrain bread / Tam tahıl ekmek', category: 'grain', per100g: Nutrients(kcal: 247, protein: 13, carbohydrate: 41, fat: 4.2, fiber: 7), servingGrams: 35),
  const Food(id: 'chicken', name: 'Cooked chicken breast / Tavuk göğsü', category: 'protein', per100g: Nutrients(kcal: 165, protein: 31, carbohydrate: 0, fat: 3.6, fiber: 0)),
  const Food(id: 'egg', name: 'Boiled egg / Haşlanmış yumurta', category: 'protein', per100g: Nutrients(kcal: 155, protein: 12.6, carbohydrate: 1.1, fat: 10.6, fiber: 0), servingGrams: 50),
  const Food(id: 'salmon', name: 'Cooked salmon / Somon', category: 'protein', per100g: Nutrients(kcal: 206, protein: 22.1, carbohydrate: 0, fat: 12.4, fiber: 0)),
  const Food(id: 'lentil', name: 'Cooked lentils / Mercimek', category: 'legume', per100g: Nutrients(kcal: 116, protein: 9, carbohydrate: 20.1, fat: .4, fiber: 7.9)),
  const Food(id: 'yogurt', name: 'Plain yogurt / Yoğurt', category: 'dairy', per100g: Nutrients(kcal: 61, protein: 3.5, carbohydrate: 4.7, fat: 3.3, fiber: 0)),
  const Food(id: 'milk', name: 'Whole milk / Tam yağlı süt', category: 'dairy', per100g: Nutrients(kcal: 61, protein: 3.2, carbohydrate: 4.8, fat: 3.3, fiber: 0), servingGrams: 200),
  const Food(id: 'cheese', name: 'White cheese / Beyaz peynir', category: 'dairy', per100g: Nutrients(kcal: 264, protein: 14, carbohydrate: 4.1, fat: 21.3, fiber: 0), servingGrams: 40),
  const Food(id: 'oliveoil', name: 'Olive oil / Zeytinyağı', category: 'fat', per100g: Nutrients(kcal: 884, protein: 0, carbohydrate: 0, fat: 100, fiber: 0), servingGrams: 10),
  const Food(id: 'almonds', name: 'Almonds / Badem', category: 'nuts', per100g: Nutrients(kcal: 579, protein: 21.2, carbohydrate: 21.6, fat: 49.9, fiber: 12.5), servingGrams: 30),
  const Food(id: 'tomato', name: 'Tomato / Domates', category: 'vegetable', per100g: Nutrients(kcal: 18, protein: .9, carbohydrate: 3.9, fat: .2, fiber: 1.2)),
  const Food(id: 'cucumber', name: 'Cucumber / Salatalık', category: 'vegetable', per100g: Nutrients(kcal: 15, protein: .7, carbohydrate: 3.6, fat: .1, fiber: .5)),
  const Food(id: 'avocado', name: 'Avocado / Avokado', category: 'fruit', per100g: Nutrients(kcal: 160, protein: 2, carbohydrate: 8.5, fat: 14.7, fiber: 6.7)),
  const Food(id: 'potato', name: 'Boiled potato / Haşlanmış patates', category: 'vegetable', per100g: Nutrients(kcal: 87, protein: 1.9, carbohydrate: 20.1, fat: .1, fiber: 1.8)),
];

List<Recipe> defaultRecipes() => [
  const Recipe(id: 'r-oats', title: 'Oat & yogurt bowl / Yoğurtlu yulaf', instructions: 'Combine yogurt, oats and sliced banana. / Yoğurt, yulaf ve dilimlenmiş muzu birleştirin.', ingredients: {'yogurt': 150, 'oats': 45, 'banana': 80}),
  const Recipe(id: 'r-salad', title: 'Chicken salad / Tavuklu salata', instructions: 'Combine cooked chicken, tomato, cucumber and olive oil. / Pişmiş tavuk, domates, salatalık ve zeytinyağını birleştirin.', ingredients: {'chicken': 120, 'tomato': 100, 'cucumber': 100, 'oliveoil': 10}),
  const Recipe(id: 'r-breakfast', title: 'Simple breakfast / Pratik kahvaltı', instructions: 'Serve eggs, bread, cheese and tomato. / Yumurta, ekmek, peynir ve domatesi servis edin.', ingredients: {'egg': 100, 'bread': 70, 'cheese': 40, 'tomato': 100}),
];

/// Food values are approximate for educational logging, never medical recommendations.