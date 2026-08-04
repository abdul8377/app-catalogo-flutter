part of '../app_database.dart';

extension _CatalogStructureSchema on AppDatabase {
  Future<void> _crearTablasEstructuraCatalogo(Database db) async {
    await db.execute('''CREATE TABLE empresas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL COLLATE NOCASE UNIQUE,
      ruc TEXT NOT NULL DEFAULT '',
      telefono TEXT NOT NULL DEFAULT '',
      direccion TEXT NOT NULL DEFAULT '',
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT
    )''');
    await db.execute('''CREATE TABLE marcas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      empresa_id INTEGER NOT NULL,
      nombre TEXT NOT NULL COLLATE NOCASE,
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      FOREIGN KEY(empresa_id) REFERENCES empresas(id),
      UNIQUE(empresa_id, nombre)
    )''');
    await db.execute('''CREATE TABLE categorias(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      categoria_padre_id INTEGER,
      nombre TEXT NOT NULL COLLATE NOCASE,
      descripcion TEXT NOT NULL DEFAULT '',
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      FOREIGN KEY(categoria_padre_id) REFERENCES categorias(id),
      UNIQUE(categoria_padre_id, nombre)
    )''');
    await db.execute('''CREATE UNIQUE INDEX idx_categoria_raiz_nombre
      ON categorias(nombre) WHERE categoria_padre_id IS NULL''');
    await db.execute('''CREATE TABLE marca_categorias(
      marca_id INTEGER NOT NULL,
      categoria_id INTEGER NOT NULL,
      estado INTEGER NOT NULL DEFAULT 1,
      actualizado_en TEXT,
      PRIMARY KEY(marca_id, categoria_id),
      FOREIGN KEY(marca_id) REFERENCES marcas(id),
      FOREIGN KEY(categoria_id) REFERENCES categorias(id)
    )''');
    await db.execute(
      'CREATE INDEX idx_marcas_empresa ON marcas(empresa_id, estado)',
    );
    await db.execute(
      'CREATE INDEX idx_categorias_padre ON categorias(categoria_padre_id, estado)',
    );
  }

  Future<void> _crearTablaColaSincronizacion(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS sync_queue(
      id TEXT PRIMARY KEY,
      entidad TEXT NOT NULL,
      entidad_id TEXT NOT NULL,
      accion TEXT NOT NULL,
      payload_json TEXT NOT NULL,
      estado TEXT NOT NULL DEFAULT 'pendiente',
      intentos INTEGER NOT NULL DEFAULT 0,
      error TEXT,
      creado_en TEXT NOT NULL,
      actualizado_en TEXT NOT NULL
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_estado ON sync_queue(estado, creado_en)',
    );
  }
}
