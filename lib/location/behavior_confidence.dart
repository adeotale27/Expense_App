import '../domain/entities/entities.dart';
import '../domain/enums/enums.dart';

class BehaviorConfidence {
  int forHome(List<VisitLog> visits) {
    if (visits.isEmpty) return 0;
    final nights = visits.where((v) => v.hourOfDay >= 21 || v.hourOfDay <= 6).length;
    final long = visits.where((v) => v.durationSeconds >= 45 * 60).length;
    final days = visits.map((v) => DateTime.utc(
          v.startedAt.year,
          v.startedAt.month,
          v.startedAt.day,
        )).toSet().length;
    var score = 0;
    score += (nights * 12).clamp(0, 40);
    score += (long * 8).clamp(0, 25);
    score += (days * 10).clamp(0, 30);
    if (visits.length >= 5) score += 10;
    return score.clamp(0, 100);
  }

  int forWork(List<VisitLog> visits) {
    if (visits.isEmpty) return 0;
    final weekdayDay = visits.where((v) {
      final weekday = v.weekday >= 1 && v.weekday <= 5;
      final day = v.hourOfDay >= 9 && v.hourOfDay <= 18;
      return weekday && day && v.durationSeconds >= 2 * 60 * 60;
    }).length;
    final days = visits.map((v) => DateTime.utc(
          v.startedAt.year,
          v.startedAt.month,
          v.startedAt.day,
        )).toSet().length;
    var score = 0;
    score += (weekdayDay * 15).clamp(0, 50);
    score += (days * 8).clamp(0, 30);
    if (visits.length >= 4) score += 10;
    return score.clamp(0, 100);
  }

  int forHangout(List<VisitLog> visits) {
    if (visits.isEmpty) return 0;
    final evenings = visits.where((v) => v.hourOfDay >= 17 && v.hourOfDay <= 23).length;
    final days = visits.map((v) => DateTime.utc(
          v.startedAt.year,
          v.startedAt.month,
          v.startedAt.day,
        )).toSet().length;
    var score = (evenings * 12).clamp(0, 40) + (days * 10).clamp(0, 30);
    if (visits.length >= 3) score += 15;
    return score.clamp(0, 100);
  }

  int forGroceryRhythm(List<VisitLog> visits) {
    if (visits.length < 3) return 0;
    final days = visits.map((v) => DateTime.utc(
          v.startedAt.year,
          v.startedAt.month,
          v.startedAt.day,
        )).toSet().length;
    return (days * 18).clamp(0, 100);
  }

  PlaceSuggestion? maybeSuggest({
    required Place place,
    required List<VisitLog> visits,
    required AppSettings settings,
    required Set<String> declinedHome,
    required Set<String> declinedWork,
    required Set<String> declinedType,
  }) {
    if (place.type != PlaceType.home &&
        settings.homeDetection &&
        !declinedHome.contains(place.id) &&
        settings.homePlaceId == null) {
      final c = forHome(visits);
      if (c >= 70) {
        return PlaceSuggestion(
          place: place,
          kind: PromptKind.homeSuggestion,
          confidence: c,
          headline: 'This place looks familiar',
          body: "You've been here most evenings. Is this your home?",
        );
      }
    }
    if (place.type != PlaceType.work &&
        settings.workDetection &&
        !declinedWork.contains(place.id) &&
        settings.workPlaceId == null) {
      final c = forWork(visits);
      if (c >= 70) {
        return PlaceSuggestion(
          place: place,
          kind: PromptKind.workSuggestion,
          confidence: c,
          headline: 'Work spot?',
          body: 'You spend a lot of weekdays here. Is this your workspace?',
        );
      }
    }
    if (place.type == PlaceType.unknown && !declinedType.contains(place.id)) {
      final hang = forHangout(visits);
      if (hang >= 65) {
        return PlaceSuggestion(
          place: place,
          kind: PromptKind.placeTypeSuggestion,
          confidence: hang,
          headline: 'Regular hangout?',
          body: "You've visited this place several times. Is this where you hang out?",
        );
      }
      final grocery = forGroceryRhythm(visits);
      if (grocery >= 65) {
        return PlaceSuggestion(
          place: place,
          kind: PromptKind.placeTypeSuggestion,
          confidence: grocery,
          headline: 'Regular grocery stop?',
          body: 'You come here often. Is this your grocery spot?',
        );
      }
    }
    return null;
  }
}
