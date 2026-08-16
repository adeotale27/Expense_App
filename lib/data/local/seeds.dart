import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../domain/entities/entities.dart';

const defaultCategorySeeds = <(String name, String icon, int color)>[
  ('Food', '🍜', 0xFFFF7A59),
  ('Grocery', '🛒', 0xFF2BB673),
  ('Fuel', '⛽', 0xFFFFB020),
  ('Transport', '🚌', 0xFF4C8DFF),
  ('Shopping', '🛍️', 0xFFE85D8C),
  ('Bills', '📄', 0xFF7C8AA5),
  ('Home', '🏠', 0xFF6D5EF7),
  ('Health', '💊', 0xFF2EC4B6),
  ('Entertainment', '🎬', 0xFFB15CFF),
  ('Gaming', '🎮', 0xFF5B8CFF),
  ('Travel', '✈️', 0xFF3D9CF0),
  ('Subscriptions', '🔁', 0xFF8B93A7),
  ('Education', '📚', 0xFF5C6BC0),
  ('Fitness', '💪', 0xFF26A69A),
  ('Personal', '✨', 0xFFC9A227),
  ('Other', '•', 0xFF8A93A6),
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
        accentColor: defaultCategorySeeds[i].$3,
        isDefault: true,
        isActive: true,
        sortOrder: i,
        createdAt: now,
        updatedAt: now,
        deviceId: deviceId,
      ),
  ];
}
