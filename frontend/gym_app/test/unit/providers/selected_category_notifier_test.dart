import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_app/features/exercises/presentation/providers/exercise_providers.dart';

void main() {
  group('SelectedCategoryNotifier', () {
    test('initial state is All', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      expect(container.read(selectedCategoryProvider), 'All');
    });

    test('setCategory updates state to new category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCategoryProvider.notifier).setCategory('Legs');
      expect(container.read(selectedCategoryProvider), 'Legs');
    });

    test('setCategory can reset back to All', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCategoryProvider.notifier).setCategory('Chest');
      container.read(selectedCategoryProvider.notifier).setCategory('All');
      expect(container.read(selectedCategoryProvider), 'All');
    });
  });
}
