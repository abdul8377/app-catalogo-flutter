class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Future<void> open() async {
    // Aqui se inicializara SQLite cuando agreguemos la dependencia.
  }
}
