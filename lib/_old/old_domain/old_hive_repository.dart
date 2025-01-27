


abstract class HiveRepository {

  // сохранить имя устройства
  Future<void> saveDeviceName(String name, String mac);

  // получить имя устройства
  Future<String> getDeviceName(String mac);

}