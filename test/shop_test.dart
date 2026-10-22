import 'package:flutter_test/flutter_test.dart';
import 'package:koin/core/db/repository.dart';
import 'package:koin/core/db/user_state.dart';
import 'package:koin/core/shop/catalog.dart';

void main() {
  test('free items are owned from the start, others once bought', () {
    final s = UserState.initial(DateTime(2026, 10, 22));
    expect(KoinRepository.owns(s, PetSpecies.kucing), isTrue);
    expect(KoinRepository.owns(s, Habitat.kamar), isTrue);
    expect(KoinRepository.owns(s, PetSpecies.kelinci), isFalse);
    s.ownedItems = [PetSpecies.kelinci.key];
    expect(KoinRepository.owns(s, PetSpecies.kelinci), isTrue);
    expect(PetSpecies.kelinci.key, 'pet:kelinci');
  });

  test('lookOf falls back to the defaults for unknown or missing names', () {
    expect(lookOf(), defaultLook);
    expect(lookOf(pet: 'naga', habitat: 'bulan'), defaultLook);
    final look = lookOf(pet: 'panda', accessory: 'mahkota', habitat: 'kutubEs');
    expect(look.pet, PetSpecies.panda);
    expect(look.accessory, Accessory.mahkota);
    expect(look.habitat, Habitat.kutubEs);
  });

  test('every item has a unique key and only the defaults are free', () {
    final items = <ShopItem>[
      ...PetSpecies.values,
      ...Accessory.values,
      ...Habitat.values,
    ];
    expect(items.map((i) => i.key).toSet(), hasLength(items.length));
    expect(items.where((i) => i.price == 0), [
      PetSpecies.kucing,
      Habitat.kamar,
    ]);
  });
}
