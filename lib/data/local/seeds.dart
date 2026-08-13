import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';

const defaultCategorySeeds = <(String name, String icon)>[
  ('Food', '🍜'),
  ('Grocery', '🛒'),
  ('Fuel', '⛽'),
  ('Transport', '🚌'),
  ('Shopping', '🛍️'),
  ('Bills', '📄'),
  ('Home', '🏠'),
  ('Health', '💊'),
  ('Entertainment', '🎬'),
  ('Travel', '✈️'),
  ('Subscriptions', '🔁'),
  ('Education', '📚'),
  ('Personal', '✨'),
  ('Other', '•'),
];

List<Category> buildDefaultCategories({
  required String userId,
  required String deviceId,
}) {
  final now = utcNow();
  return [
    for (var i = 0; i < defaultCategorySeeds.length; i++)
      Category(
        id: newId(),
        userId: userId,
        name: defaultCategorySeeds[i].$1,
        icon: defaultCategorySeeds[i].$2,
        isDefault: true,
        isActive: true,
        sortOrder: i,
        createdAt: now,
        updatedAt: now,
        deviceId: deviceId,
      ),
  ];
}
