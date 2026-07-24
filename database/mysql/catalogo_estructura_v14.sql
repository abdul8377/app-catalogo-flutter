-- Estructura administrativa del catálogo.
-- Aplicar dentro de una transacción y respaldar la base antes de migrar datos.

CREATE TABLE IF NOT EXISTS empresas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(160) NOT NULL,
  ruc VARCHAR(20) NOT NULL DEFAULT '',
  telefono VARCHAR(40) NOT NULL DEFAULT '',
  direccion VARCHAR(300) NOT NULL DEFAULT '',
  estado TINYINT(1) NOT NULL DEFAULT 1,
  actualizado_en DATETIME(3) NULL,
  UNIQUE KEY uq_empresas_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS marcas (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empresa_id BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(160) NOT NULL,
  estado TINYINT(1) NOT NULL DEFAULT 1,
  actualizado_en DATETIME(3) NULL,
  CONSTRAINT fk_marcas_empresa
    FOREIGN KEY (empresa_id) REFERENCES empresas(id),
  UNIQUE KEY uq_marcas_empresa_nombre (empresa_id, nombre),
  KEY idx_marcas_empresa_estado (empresa_id, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS categorias (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  categoria_padre_id BIGINT UNSIGNED NULL,
  nombre VARCHAR(160) NOT NULL,
  descripcion VARCHAR(500) NOT NULL DEFAULT '',
  estado TINYINT(1) NOT NULL DEFAULT 1,
  actualizado_en DATETIME(3) NULL,
  nivel_clave BIGINT
    GENERATED ALWAYS AS (COALESCE(categoria_padre_id, 0)) STORED,
  CONSTRAINT fk_categorias_padre
    FOREIGN KEY (categoria_padre_id) REFERENCES categorias(id),
  UNIQUE KEY uq_categorias_nivel_nombre (nivel_clave, nombre),
  KEY idx_categorias_padre_estado (categoria_padre_id, estado),
  CONSTRAINT chk_categoria_no_autoreferencia
    CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS marca_categorias (
  marca_id BIGINT UNSIGNED NOT NULL,
  categoria_id BIGINT UNSIGNED NOT NULL,
  estado TINYINT(1) NOT NULL DEFAULT 1,
  actualizado_en DATETIME(3) NULL,
  PRIMARY KEY (marca_id, categoria_id),
  CONSTRAINT fk_marca_categorias_marca
    FOREIGN KEY (marca_id) REFERENCES marcas(id),
  CONSTRAINT fk_marca_categorias_categoria
    FOREIGN KEY (categoria_id) REFERENCES categorias(id),
  KEY idx_marca_categorias_categoria_estado (categoria_id, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sync_queue (
  id CHAR(36) PRIMARY KEY,
  entidad VARCHAR(60) NOT NULL,
  entidad_id VARCHAR(80) NOT NULL,
  accion VARCHAR(60) NOT NULL,
  payload_json JSON NOT NULL,
  estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
  intentos INT UNSIGNED NOT NULL DEFAULT 0,
  error TEXT NULL,
  creado_en DATETIME(3) NOT NULL,
  actualizado_en DATETIME(3) NOT NULL,
  KEY idx_sync_queue_estado_creado (estado, creado_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reglas que deben conservarse también en el servicio Spring/API:
-- 1. No borrar físicamente empresas, marcas, categorías ni relaciones usadas.
-- 2. No desvincular una marca/categoría con productos activos.
-- 3. Una entidad inactiva no participa en nuevos registros.
-- 4. Crear "Sin marca" por empresa cuando esta se registra.
-- 5. Publicar los cambios de estas cuatro entidades mediante la cola offline.
