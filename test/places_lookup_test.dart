import 'package:flutter_test/flutter_test.dart';
import 'package:spendping/domain/enums/enums.dart';
import 'package:spendping/location/google_places.dart';
import 'package:spendping/location/place_classifier.dart';

void main() {
  test('nearby search prefers a restaurant over a street', () {
    final hint = GooglePlacesLookup.pickBest(
      {
        'results': [
          {
            'name': 'FC Road',
            'types': ['route'],
          },
          {
            'name': 'Vaishali Restaurant',
            'types': ['restaurant', 'food', 'point_of_interest'],
          },
        ],
      },
      PlaceClassifier(),
    );
    expect(hint?.name, 'Vaishali Restaurant');
    expect(hint?.type, PlaceType.food);
  });

  test('gas station maps to fuel', () {
    final hint = GooglePlacesLookup.pickBest(
      {
        'results': [
          {
            'name': 'Indian Oil',
            'types': ['gas_station', 'point_of_interest'],
          },
        ],
      },
      PlaceClassifier(),
    );
    expect(hint?.type, PlaceType.fuel);
  });

  test('classifier reads restaurant brand names', () {
    expect(PlaceClassifier().classifyName("McDonald's Koregaon"), PlaceType.food);
  });
}
