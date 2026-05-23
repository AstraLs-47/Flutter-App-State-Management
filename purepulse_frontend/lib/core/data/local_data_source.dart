abstract class LocalDataSource<T> {
  Future<List<T>> getAll();
  Future<void> save(T item);
  Future<void> saveAll(List<T> items);
  Future<void> update(T item);
  Future<void> delete(String id);
  Future<void> clear();
}
