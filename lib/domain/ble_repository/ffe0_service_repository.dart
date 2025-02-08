

abstract class FFE0ServiceRepository {

  Future<void> ffe0Connect();

  Future<Stream<Map<String, dynamic>>> ffe0Stream();

}