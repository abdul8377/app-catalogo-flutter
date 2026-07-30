-- ============================================================
-- App Catálogo Comercial Offline-First
-- Esquema MySQL central
-- Versión: 8.0
-- Compatibilidad objetivo: MySQL 8.0.
-- Descripción:
--   Base central para backend Spring Boot.
--   No incluye tablas catalogos ni catalogo_versiones.
--   Modelo actualizado con categorías globales, relaciones marca-categoría,
--   atributos tipados y heredables, unidades normalizadas, ejes elegidos por
--   familia, variantes, presentaciones, precios e imágenes,
--   hojas de pedido, descuentos y cotizaciones.
-- ============================================================

CREATE DATABASE IF NOT EXISTS app_catalogo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE app_catalogo;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS vw_clientes_por_producto_hoja;
DROP VIEW IF EXISTS vw_productos_consolidados_hoja;
DROP VIEW IF EXISTS vw_categoria_atributos_efectivos;
DROP VIEW IF EXISTS vw_categoria_atributos_invalidos;

DROP TRIGGER IF EXISTS trg_producto_atributo_normalizar_insert;
DROP TRIGGER IF EXISTS trg_producto_atributo_normalizar_update;
DROP TRIGGER IF EXISTS trg_familia_eje_insert;
DROP TRIGGER IF EXISTS trg_familia_eje_update;
DROP TRIGGER IF EXISTS trg_atributo_proteger_estructura;
DROP TRIGGER IF EXISTS trg_atributo_proteger_eje;
DROP TRIGGER IF EXISTS trg_atributo_no_eliminar_usado;
DROP TRIGGER IF EXISTS trg_opcion_no_eliminar_usada;
DROP TRIGGER IF EXISTS trg_opcion_proteger_codigo;
DROP TRIGGER IF EXISTS trg_unidad_no_eliminar_usada;
DROP TRIGGER IF EXISTS trg_unidad_proteger_update;
DROP TRIGGER IF EXISTS trg_unidad_magnitud_insert;
DROP TRIGGER IF EXISTS trg_unidad_magnitud_update;
DROP TRIGGER IF EXISTS trg_atributo_cadena_insert;
DROP TRIGGER IF EXISTS trg_atributo_cadena_update;
DROP TRIGGER IF EXISTS trg_marca_categoria_no_desactivar_usada;
DROP TRIGGER IF EXISTS trg_marca_categoria_no_eliminar_usada;
DROP TRIGGER IF EXISTS trg_familia_clasificacion_insert;
DROP TRIGGER IF EXISTS trg_familia_clasificacion_update;

DROP TABLE IF EXISTS auditoria;
DROP TABLE IF EXISTS sync_queue;
DROP TABLE IF EXISTS gestion_producto_hoja;
DROP TABLE IF EXISTS cotizacion_detalles;
DROP TABLE IF EXISTS cotizaciones_pedido;
DROP TABLE IF EXISTS pedido_detalles;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS hojas_pedido;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS producto_imagen_excepciones;
DROP TABLE IF EXISTS producto_imagenes;
DROP TABLE IF EXISTS producto_precio_rangos;
DROP TABLE IF EXISTS producto_precios;
DROP TABLE IF EXISTS listas_precios;
DROP TABLE IF EXISTS producto_presentaciones;
DROP TABLE IF EXISTS producto_atributo_opciones;
DROP TABLE IF EXISTS producto_atributos;
DROP TABLE IF EXISTS producto_familia_ejes;
DROP TABLE IF EXISTS producto_variantes;
DROP TABLE IF EXISTS producto_familias;
DROP TABLE IF EXISTS categoria_atributo_unidades;
DROP TABLE IF EXISTS categoria_atributo_opciones;
DROP TABLE IF EXISTS categoria_atributos;
DROP TABLE IF EXISTS unidades_medida;
DROP TABLE IF EXISTS marca_categorias;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS marcas;
DROP TABLE IF EXISTS empresas;
DROP TABLE IF EXISTS vendedores;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS roles;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- Seguridad y usuarios
-- ============================================================

CREATE TABLE roles (
    id CHAR(36) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NULL,
    permisos JSON NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id CHAR(36) PRIMARY KEY,
    rol_id CHAR(36) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    usuario VARCHAR(80) NOT NULL UNIQUE,
    clave_hash VARCHAR(255) NOT NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    ultimo_acceso DATETIME(3) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    CONSTRAINT fk_usuarios_roles
      FOREIGN KEY (rol_id) REFERENCES roles(id)
) ENGINE=InnoDB;

CREATE TABLE vendedores (
    id CHAR(36) PRIMARY KEY,
    usuario_id CHAR(36) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    documento VARCHAR(20) NULL,
    telefono VARCHAR(30) NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    CONSTRAINT fk_vendedores_usuarios
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- ============================================================
-- Empresas, marcas y clasificación
-- ============================================================

CREATE TABLE empresas (
    id CHAR(36) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    ruc VARCHAR(20) NULL,
    telefono VARCHAR(40) NULL,
    direccion VARCHAR(255) NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    UNIQUE KEY uq_empresa_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE marcas (
    id CHAR(36) PRIMARY KEY,
    empresa_id CHAR(36) NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    CONSTRAINT fk_marcas_empresas
      FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    UNIQUE KEY uq_marca_empresa_nombre (empresa_id, nombre)
) ENGINE=InnoDB;

-- Las categorías son globales: no contienen empresa_id.
CREATE TABLE categorias (
    id CHAR(36) PRIMARY KEY,
    categoria_padre_id CHAR(36) NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(500) NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    categoria_scope CHAR(36)
      GENERATED ALWAYS AS (
        COALESCE(categoria_padre_id, '00000000-0000-0000-0000-000000000000')
      ) STORED,
    CONSTRAINT fk_categorias_padre
      FOREIGN KEY (categoria_padre_id) REFERENCES categorias(id),
    CONSTRAINT chk_categoria_no_autoreferencia
      CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id),
    UNIQUE KEY uq_categoria_padre_nombre (categoria_scope, nombre)
) ENGINE=InnoDB;

CREATE TABLE marca_categorias (
    marca_id CHAR(36) NOT NULL,
    categoria_id CHAR(36) NOT NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (marca_id, categoria_id),
    CONSTRAINT fk_marca_categorias_marca
      FOREIGN KEY (marca_id) REFERENCES marcas(id),
    CONSTRAINT fk_marca_categorias_categoria
      FOREIGN KEY (categoria_id) REFERENCES categorias(id),
    KEY idx_marca_categorias_categoria (categoria_id, estado)
) ENGINE=InnoDB;

CREATE TABLE unidades_medida (
    id CHAR(36) PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    simbolo VARCHAR(20) NOT NULL,
    magnitud VARCHAR(60) NOT NULL,
    factor_a_base DECIMAL(24,12) NOT NULL,
    desplazamiento_a_base DECIMAL(24,12) NOT NULL DEFAULT 0,
    es_unidad_base TINYINT(1) NOT NULL DEFAULT 0,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    base_scope VARCHAR(60)
      GENERATED ALWAYS AS (
        CASE
          WHEN es_unidad_base = 1 AND estado = 1 THEN magnitud
          ELSE NULL
        END
      ) STORED,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    CONSTRAINT chk_unidad_factor_positivo CHECK (factor_a_base > 0),
    UNIQUE KEY uq_unidad_codigo (codigo),
    UNIQUE KEY uq_unidad_base_magnitud (base_scope),
    KEY idx_unidad_magnitud (magnitud, estado)
) ENGINE=InnoDB;

CREATE TABLE categoria_atributos (
    id CHAR(36) PRIMARY KEY,
    categoria_id CHAR(36) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    clave VARCHAR(120) NOT NULL,
    texto_ayuda VARCHAR(500) NULL,
    tipo_dato ENUM(
      'texto_corto',
      'numero',
      'numero_unidad',
      'lista_unica',
      'lista_multiple',
      'booleano'
    ) NOT NULL,
    nivel_captura_recomendado ENUM(
      'familia',
      'variante',
      'decidir_producto'
    ) NOT NULL DEFAULT 'decidir_producto',
    obligatorio_activacion TINYINT(1) NOT NULL DEFAULT 0,
    mostrar_ficha TINYINT(1) NOT NULL DEFAULT 1,
    filtrable TINYINT(1) NOT NULL DEFAULT 0,
    permite_eje_variante TINYINT(1) NOT NULL DEFAULT 0,
    activo_nuevos_productos TINYINT(1) NOT NULL DEFAULT 1,
    orden INT UNSIGNED NOT NULL DEFAULT 0,
    longitud_maxima INT UNSIGNED NULL,
    ejemplo VARCHAR(255) NULL,
    valor_minimo DECIMAL(24,8) NULL,
    valor_maximo DECIMAL(24,8) NULL,
    decimales TINYINT UNSIGNED NOT NULL DEFAULT 0,
    magnitud VARCHAR(60) NULL,
    maximo_selecciones INT UNSIGNED NULL,
    etiqueta_verdadero VARCHAR(80) NULL,
    etiqueta_falso VARCHAR(80) NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    CONSTRAINT fk_categoria_atributos_categoria
      FOREIGN KEY (categoria_id) REFERENCES categorias(id),
    CONSTRAINT chk_atributo_rango
      CHECK (
        valor_minimo IS NULL
        OR valor_maximo IS NULL
        OR valor_minimo <= valor_maximo
      ),
    CONSTRAINT chk_atributo_decimales CHECK (decimales BETWEEN 0 AND 6),
    CONSTRAINT chk_atributo_eje_tipo
      CHECK (
        permite_eje_variante = 0
        OR tipo_dato IN ('numero', 'numero_unidad', 'lista_unica')
      ),
    CONSTRAINT chk_atributo_magnitud
      CHECK (tipo_dato = 'numero_unidad' OR magnitud IS NULL),
    CONSTRAINT chk_atributo_max_selecciones
      CHECK (tipo_dato = 'lista_multiple' OR maximo_selecciones IS NULL),
    UNIQUE KEY uq_categoria_atributo_nombre (categoria_id, nombre),
    UNIQUE KEY uq_categoria_atributo_clave (categoria_id, clave),
    KEY idx_categoria_atributos_categoria (categoria_id, estado, orden)
) ENGINE=InnoDB;

CREATE TABLE categoria_atributo_opciones (
    id CHAR(36) PRIMARY KEY,
    categoria_atributo_id CHAR(36) NOT NULL,
    etiqueta VARCHAR(150) NOT NULL,
    codigo VARCHAR(100) NOT NULL,
    orden INT UNSIGNED NOT NULL DEFAULT 0,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    CONSTRAINT fk_categoria_atributo_opciones_atributo
      FOREIGN KEY (categoria_atributo_id) REFERENCES categoria_atributos(id),
    UNIQUE KEY uq_categoria_atributo_opcion_etiqueta
      (categoria_atributo_id, etiqueta),
    UNIQUE KEY uq_categoria_atributo_opcion_codigo
      (categoria_atributo_id, codigo),
    UNIQUE KEY uq_categoria_atributo_opcion_id_def
      (id, categoria_atributo_id),
    KEY idx_categoria_atributo_opciones
      (categoria_atributo_id, estado, orden)
) ENGINE=InnoDB;

CREATE TABLE categoria_atributo_unidades (
    id CHAR(36) PRIMARY KEY,
    categoria_atributo_id CHAR(36) NOT NULL,
    unidad_medida_id CHAR(36) NOT NULL,
    es_predeterminada TINYINT(1) NOT NULL DEFAULT 0,
    orden INT UNSIGNED NOT NULL DEFAULT 0,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    default_scope CHAR(36)
      GENERATED ALWAYS AS (
        CASE
          WHEN es_predeterminada = 1 AND estado = 1
          THEN categoria_atributo_id
          ELSE NULL
        END
      ) STORED,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    CONSTRAINT fk_categoria_atributo_unidades_atributo
      FOREIGN KEY (categoria_atributo_id) REFERENCES categoria_atributos(id),
    CONSTRAINT fk_categoria_atributo_unidades_unidad
      FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id),
    UNIQUE KEY uq_categoria_atributo_unidad
      (categoria_atributo_id, unidad_medida_id),
    UNIQUE KEY uq_categoria_atributo_unidad_predeterminada (default_scope),
    UNIQUE KEY uq_categoria_atributo_unidad_id_def
      (id, categoria_atributo_id),
    KEY idx_categoria_atributo_unidades
      (categoria_atributo_id, estado, orden)
) ENGINE=InnoDB;

-- ============================================================
-- Productos: familia, variante, atributos, presentaciones y precios
-- ============================================================

CREATE TABLE producto_familias (
    id CHAR(36) PRIMARY KEY,
    empresa_id CHAR(36) NOT NULL,
    marca_id CHAR(36) NOT NULL,
    categoria_id CHAR(36) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT NULL,
    tipo_producto VARCHAR(120) NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    CONSTRAINT fk_familias_empresas
      FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_familias_marcas
      FOREIGN KEY (marca_id) REFERENCES marcas(id),
    CONSTRAINT fk_familias_categorias
      FOREIGN KEY (categoria_id) REFERENCES categorias(id)
) ENGINE=InnoDB;

CREATE TABLE producto_variantes (
    id CHAR(36) PRIMARY KEY,
    familia_id CHAR(36) NOT NULL,
    empresa_id CHAR(36) NOT NULL,
    marca_id CHAR(36) NOT NULL,
    codigo VARCHAR(100) NULL,
    nombre_comercial VARCHAR(255) NOT NULL,
    descripcion_corta TEXT NULL,
    unidad_venta VARCHAR(50) NOT NULL DEFAULT 'UND',

    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,

    CONSTRAINT fk_variantes_familias
      FOREIGN KEY (familia_id) REFERENCES producto_familias(id),
    CONSTRAINT fk_variantes_empresas
      FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_variantes_marcas
      FOREIGN KEY (marca_id) REFERENCES marcas(id),

    UNIQUE KEY uq_empresa_codigo_variante (empresa_id, codigo),

    -- Necesaria para validar que una excepción use una imagen de su familia.
    UNIQUE KEY uq_variante_id_familia (id, familia_id)
) ENGINE=InnoDB;

CREATE TABLE producto_familia_ejes (
    familia_id CHAR(36) NOT NULL,
    categoria_atributo_id CHAR(36) NOT NULL,
    orden INT UNSIGNED NOT NULL DEFAULT 0,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (familia_id, categoria_atributo_id),
    CONSTRAINT fk_familia_ejes_familia
      FOREIGN KEY (familia_id) REFERENCES producto_familias(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_familia_ejes_atributo
      FOREIGN KEY (categoria_atributo_id) REFERENCES categoria_atributos(id),
    KEY idx_familia_ejes_atributo (categoria_atributo_id, familia_id)
) ENGINE=InnoDB;

CREATE TABLE producto_atributos (
    id CHAR(36) PRIMARY KEY,
    categoria_atributo_id CHAR(36) NOT NULL,
    familia_id CHAR(36) NULL,
    variante_id CHAR(36) NULL,
    valor_texto VARCHAR(500) NULL,
    valor_numero DECIMAL(18,6) NULL,
    valor_normalizado DECIMAL(24,8) NULL,
    valor_booleano TINYINT(1) NULL,
    unidad_id CHAR(36) NULL,
    propietario_tipo VARCHAR(8)
      GENERATED ALWAYS AS (
        CASE WHEN familia_id IS NOT NULL THEN 'familia' ELSE 'variante' END
      ) STORED,
    propietario_id CHAR(36)
      GENERATED ALWAYS AS (COALESCE(familia_id, variante_id)) STORED,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    CONSTRAINT fk_producto_atributos_definicion
      FOREIGN KEY (categoria_atributo_id) REFERENCES categoria_atributos(id),
    CONSTRAINT fk_producto_atributos_familia
      FOREIGN KEY (familia_id) REFERENCES producto_familias(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_producto_atributos_variante
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_producto_atributos_unidad
      FOREIGN KEY (unidad_id, categoria_atributo_id)
      REFERENCES categoria_atributo_unidades(id, categoria_atributo_id),
    CONSTRAINT chk_producto_atributo_propietario
      CHECK (
        (familia_id IS NOT NULL AND variante_id IS NULL)
        OR (familia_id IS NULL AND variante_id IS NOT NULL)
      ),
    CONSTRAINT chk_producto_atributo_normalizado
      CHECK (valor_numero IS NOT NULL OR valor_normalizado IS NULL),
    UNIQUE KEY uq_producto_atributo_propietario
      (propietario_tipo, propietario_id, categoria_atributo_id),
    UNIQUE KEY uq_producto_atributo_id_def
      (id, categoria_atributo_id),
    KEY idx_producto_atributos_definicion (categoria_atributo_id),
    KEY idx_producto_atributos_familia (familia_id),
    KEY idx_producto_atributos_variante (variante_id),
    KEY idx_producto_atributos_normalizados
      (categoria_atributo_id, valor_normalizado)
) ENGINE=InnoDB;

CREATE TABLE producto_atributo_opciones (
    producto_atributo_id CHAR(36) NOT NULL,
    categoria_atributo_id CHAR(36) NOT NULL,
    opcion_id CHAR(36) NOT NULL,
    PRIMARY KEY (producto_atributo_id, opcion_id),
    CONSTRAINT fk_producto_atributo_opciones_valor
      FOREIGN KEY (producto_atributo_id, categoria_atributo_id)
      REFERENCES producto_atributos(id, categoria_atributo_id)
      ON DELETE CASCADE,
    CONSTRAINT fk_producto_atributo_opciones_opcion
      FOREIGN KEY (opcion_id, categoria_atributo_id)
      REFERENCES categoria_atributo_opciones(id, categoria_atributo_id),
    KEY idx_producto_atributo_opciones_opcion (opcion_id)
) ENGINE=InnoDB;

CREATE TABLE producto_presentaciones (
    id CHAR(36) PRIMARY KEY,
    variante_id CHAR(36) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    cantidad DECIMAL(12,3) NOT NULL DEFAULT 1,
    unidad VARCHAR(50) NOT NULL,
    es_venta_minima TINYINT(1) NOT NULL DEFAULT 0,
    es_empaque TINYINT(1) NOT NULL DEFAULT 0,
    es_caja TINYINT(1) NOT NULL DEFAULT 0,
    descripcion VARCHAR(255) NULL,
    CONSTRAINT fk_presentaciones_variantes
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
      ON DELETE CASCADE,
    UNIQUE KEY uq_presentacion_variante (id, variante_id)
) ENGINE=InnoDB;

-- Una lista concentra moneda, tratamiento de IGV y vigencia.
-- Los importes de producto_precios heredan esta configuración.
CREATE TABLE listas_precios (
    id CHAR(36) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    moneda ENUM('PEN', 'USD', 'EUR') NOT NULL DEFAULT 'PEN',
    incluye_igv TINYINT(1) NOT NULL DEFAULT 1,
    vigencia_desde DATE NOT NULL,
    vigencia_hasta DATE NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),

    UNIQUE KEY uq_lista_precio_nombre (nombre),
    CONSTRAINT chk_lista_precio_vigencia
      CHECK (
        vigencia_hasta IS NULL
        OR vigencia_hasta >= vigencia_desde
      )
) ENGINE=InnoDB;

-- Cada registro representa una decisión completa para:
-- lista + variante + presentación vendible.
-- "Sin configurar" es la ausencia de este registro.
CREATE TABLE producto_precios (
    id CHAR(36) PRIMARY KEY,
    lista_precio_id CHAR(36) NOT NULL,
    variante_id CHAR(36) NOT NULL,
    presentacion_id CHAR(36) NOT NULL,
    configuracion ENUM(
      'precio_fijo',
      'por_cantidad',
      'por_cotizar'
    ) NOT NULL,
    precio_fijo DECIMAL(12,2) NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_precios_listas
      FOREIGN KEY (lista_precio_id) REFERENCES listas_precios(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_precios_presentacion_variante
      FOREIGN KEY (presentacion_id, variante_id)
      REFERENCES producto_presentaciones(id, variante_id)
      ON DELETE CASCADE,

    UNIQUE KEY uq_precio_lista_variante_presentacion
      (lista_precio_id, variante_id, presentacion_id),

    CONSTRAINT chk_producto_precio_configuracion
      CHECK (
        (
          configuracion = 'precio_fijo'
          AND precio_fijo IS NOT NULL
          AND precio_fijo >= 0
        )
        OR (
          configuracion IN ('por_cantidad', 'por_cotizar')
          AND precio_fijo IS NULL
        )
      )
) ENGINE=InnoDB;

-- Solo se crean rangos cuando configuracion = 'por_cantidad'.
-- La aplicación valida continuidad y ausencia de superposiciones.
CREATE TABLE producto_precio_rangos (
    id CHAR(36) PRIMARY KEY,
    producto_precio_id CHAR(36) NOT NULL,
    cantidad_desde DECIMAL(12,3) NOT NULL,
    cantidad_hasta DECIMAL(12,3) NULL,
    precio_presentacion DECIMAL(12,2) NOT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_precio_rangos_precio
      FOREIGN KEY (producto_precio_id)
      REFERENCES producto_precios(id)
      ON DELETE CASCADE,

    UNIQUE KEY uq_precio_rango_desde
      (producto_precio_id, cantidad_desde),

    CONSTRAINT chk_precio_rango_desde
      CHECK (cantidad_desde > 0),
    CONSTRAINT chk_precio_rango_hasta
      CHECK (
        cantidad_hasta IS NULL
        OR cantidad_hasta >= cantidad_desde
      ),
    CONSTRAINT chk_precio_rango_importe
      CHECK (precio_presentacion >= 0)
) ENGINE=InnoDB;

-- ============================================================
-- Imágenes, galería familiar y excepciones por variante
-- ============================================================
--
-- La galería se guarda una sola vez con familia_id.
-- Una imagen específica usa variante_id.
-- La restricción XOR impide que una imagen pertenezca a ambas.
CREATE TABLE producto_imagenes (
    id CHAR(36) PRIMARY KEY,
    familia_id CHAR(36) NULL,
    variante_id CHAR(36) NULL,

    tipo ENUM('thumb', 'detalle', 'referencial')
      NOT NULL DEFAULT 'detalle',
    etiqueta VARCHAR(80) NOT NULL DEFAULT 'Detalle',
    es_principal TINYINT(1) NOT NULL DEFAULT 0,
    orden INT UNSIGNED NOT NULL DEFAULT 0,

    ruta_archivo VARCHAR(500) NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    mime_type ENUM('image/jpeg', 'image/png', 'image/webp') NOT NULL,
    tamano_bytes BIGINT UNSIGNED NOT NULL,
    ancho_px INT UNSIGNED NULL,
    alto_px INT UNSIGNED NULL,
    checksum_sha256 CHAR(64) NULL,

    estado_procesamiento ENUM('procesando', 'lista', 'error')
      NOT NULL DEFAULT 'lista',
    error_procesamiento TEXT NULL,

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,

    -- Claves generadas para imponer unicidad solo sobre filas activas.
    principal_familia_key CHAR(36)
      GENERATED ALWAYS AS (
        CASE
          WHEN es_principal = 1 AND deleted_at IS NULL
            THEN familia_id
          ELSE NULL
        END
      ) STORED,
    principal_variante_key CHAR(36)
      GENERATED ALWAYS AS (
        CASE
          WHEN es_principal = 1 AND deleted_at IS NULL
            THEN variante_id
          ELSE NULL
        END
      ) STORED,
    orden_familia_activa INT
      GENERATED ALWAYS AS (
        CASE
          WHEN familia_id IS NOT NULL AND deleted_at IS NULL
            THEN orden
          ELSE NULL
        END
      ) STORED,
    orden_variante_activa INT
      GENERATED ALWAYS AS (
        CASE
          WHEN variante_id IS NOT NULL AND deleted_at IS NULL
            THEN orden
          ELSE NULL
        END
      ) STORED,

    CONSTRAINT chk_imagen_propietario_xor
      CHECK (
        (
          familia_id IS NOT NULL
          AND variante_id IS NULL
        )
        OR
        (
          familia_id IS NULL
          AND variante_id IS NOT NULL
        )
      ),
    CONSTRAINT chk_imagen_es_principal
      CHECK (es_principal IN (0, 1)),
    CONSTRAINT chk_imagen_tamano
      CHECK (tamano_bytes > 0),
    CONSTRAINT chk_imagen_ancho
      CHECK (ancho_px IS NULL OR ancho_px > 0),
    CONSTRAINT chk_imagen_alto
      CHECK (alto_px IS NULL OR alto_px > 0),

    CONSTRAINT fk_imagenes_variantes
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_imagenes_familias
      FOREIGN KEY (familia_id) REFERENCES producto_familias(id)
      ON DELETE CASCADE,

    UNIQUE KEY uq_imagen_id_familia (id, familia_id),
    UNIQUE KEY uq_imagen_id_variante (id, variante_id),
    UNIQUE KEY uq_imagen_principal_familia (principal_familia_key),
    UNIQUE KEY uq_imagen_principal_variante (principal_variante_key),
    UNIQUE KEY uq_imagen_orden_familia
      (familia_id, orden_familia_activa),
    UNIQUE KEY uq_imagen_orden_variante
      (variante_id, orden_variante_activa)
) ENGINE=InnoDB;

-- La ausencia de una fila significa "hereda la principal familiar".
-- Una fila puede apuntar a otra imagen de la galería de la misma familia
-- o a una imagen específica de la misma variante, nunca a las dos.
-- Si una imagen se elimina de forma lógica, el servicio debe borrar su
-- excepción en la misma transacción; ON DELETE CASCADE cubre el borrado físico.
CREATE TABLE producto_imagen_excepciones (
    variante_id CHAR(36) PRIMARY KEY,
    familia_id CHAR(36) NOT NULL,
    imagen_familia_id CHAR(36) NULL,
    imagen_variante_id CHAR(36) NULL,

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
      ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT chk_imagen_excepcion_origen_xor
      CHECK (
        (
          imagen_familia_id IS NOT NULL
          AND imagen_variante_id IS NULL
        )
        OR
        (
          imagen_familia_id IS NULL
          AND imagen_variante_id IS NOT NULL
        )
      ),

    CONSTRAINT fk_imagen_excepcion_variante_familia
      FOREIGN KEY (variante_id, familia_id)
      REFERENCES producto_variantes(id, familia_id)
      ON DELETE CASCADE,
    CONSTRAINT fk_imagen_excepcion_imagen_familia
      FOREIGN KEY (imagen_familia_id, familia_id)
      REFERENCES producto_imagenes(id, familia_id)
      ON DELETE CASCADE,
    CONSTRAINT fk_imagen_excepcion_imagen_variante
      FOREIGN KEY (imagen_variante_id, variante_id)
      REFERENCES producto_imagenes(id, variante_id)
      ON DELETE CASCADE,

    KEY idx_imagen_excepciones_familia (familia_id),
    KEY idx_imagen_excepciones_imagen_familia (imagen_familia_id),
    KEY idx_imagen_excepciones_imagen_variante (imagen_variante_id)
) ENGINE=InnoDB;

-- ============================================================
-- Clientes
-- ============================================================

CREATE TABLE clientes (
    id CHAR(36) PRIMARY KEY,
    nombre_razon_social VARCHAR(200) NOT NULL,
    dni_ruc VARCHAR(20) NULL,
    telefono VARCHAR(30) NOT NULL,
    direccion TEXT NOT NULL,
    referencia TEXT NULL,
    foto_referencia VARCHAR(500) NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    UNIQUE KEY uq_cliente_dni_ruc (dni_ruc)
) ENGINE=InnoDB;

-- ============================================================
-- Hojas de pedido, pedidos y detalles
-- ============================================================

CREATE TABLE hojas_pedido (
    id CHAR(36) PRIMARY KEY,
    codigo_hoja VARCHAR(50) NOT NULL UNIQUE,
    vendedor_id CHAR(36) NOT NULL,

    fecha_creacion DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    fecha_cierre DATETIME(3) NULL,

    estado ENUM('abierta', 'completada') NOT NULL DEFAULT 'abierta',

    total_estimado_catalogo DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_estimado_final DECIMAL(12,2) NOT NULL DEFAULT 0,

    cantidad_pedidos INT NOT NULL DEFAULT 0,
    cantidad_productos DECIMAL(12,3) NOT NULL DEFAULT 0,

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_hojas_vendedores
      FOREIGN KEY (vendedor_id) REFERENCES vendedores(id)
) ENGINE=InnoDB;

CREATE TABLE pedidos (
    id CHAR(36) PRIMARY KEY,
    codigo_pedido VARCHAR(50) NOT NULL UNIQUE,

    hoja_id CHAR(36) NOT NULL,
    cliente_id CHAR(36) NOT NULL,
    vendedor_id CHAR(36) NOT NULL,

    fecha DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    estado ENUM('pendiente', 'en_proceso', 'listo_para_entregar', 'entregado', 'cancelado')
        NOT NULL DEFAULT 'pendiente',

    total_catalogo DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_rebajado_items DECIMAL(12,2) NOT NULL DEFAULT 0,

    descuento_global_tipo ENUM('ninguno', 'monto', 'porcentaje') NOT NULL DEFAULT 'ninguno',
    descuento_global_valor DECIMAL(12,2) NOT NULL DEFAULT 0,

    total_final DECIMAL(12,2) NOT NULL DEFAULT 0,

    tiene_productos_sin_precio TINYINT(1) NOT NULL DEFAULT 0,
    total_es_parcial TINYINT(1) NOT NULL DEFAULT 0,

    precio_editado TINYINT(1) NOT NULL DEFAULT 0,
    motivo_descuento VARCHAR(255) NULL,

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,

    CONSTRAINT fk_pedidos_hojas
      FOREIGN KEY (hoja_id) REFERENCES hojas_pedido(id),
    CONSTRAINT fk_pedidos_clientes
      FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_pedidos_vendedores
      FOREIGN KEY (vendedor_id) REFERENCES vendedores(id)
) ENGINE=InnoDB;

CREATE TABLE pedido_detalles (
    id CHAR(36) PRIMARY KEY,
    pedido_id CHAR(36) NOT NULL,
    variante_id CHAR(36) NOT NULL,

    cantidad DECIMAL(12,3) NOT NULL,
    unidad VARCHAR(50) NOT NULL,

    precio_unitario_catalogo DECIMAL(12,2) NULL,
    precio_unitario_final DECIMAL(12,2) NULL,

    subtotal_catalogo DECIMAL(12,2) NULL,
    subtotal_final DECIMAL(12,2) NULL,

    descuento_item_tipo ENUM('ninguno', 'monto', 'porcentaje', 'precio_manual')
        NOT NULL DEFAULT 'ninguno',
    descuento_item_valor DECIMAL(12,2) NOT NULL DEFAULT 0,

    sin_precio TINYINT(1) NOT NULL DEFAULT 0,

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_detalles_pedidos
      FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_detalles_variantes
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
) ENGINE=InnoDB;

-- ============================================================
-- Cotizaciones / presupuestos exportados
-- ============================================================

CREATE TABLE cotizaciones_pedido (
    id CHAR(36) PRIMARY KEY,
    pedido_id CHAR(36) NOT NULL,
    numero_documento VARCHAR(60) NOT NULL UNIQUE,
    tipo_documento ENUM('cotizacion', 'presupuesto', 'proforma') NOT NULL DEFAULT 'cotizacion',
    fecha_emision DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    usuario_emision_id CHAR(36) NULL,

    cliente_nombre_snapshot VARCHAR(200) NOT NULL,
    cliente_documento_snapshot VARCHAR(20) NULL,
    cliente_telefono_snapshot VARCHAR(30) NULL,
    cliente_direccion_snapshot TEXT NULL,

    moneda CHAR(3) NOT NULL DEFAULT 'PEN',
    subtotal_items DECIMAL(12,2) NOT NULL DEFAULT 0,
    descuento_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_sin_igv DECIMAL(12,2) NOT NULL DEFAULT 0,
    igv_porcentaje DECIMAL(5,2) NOT NULL DEFAULT 18.00,
    igv_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_final DECIMAL(12,2) NOT NULL DEFAULT 0,

    archivo_ruta VARCHAR(500) NULL,
    estado ENUM('generada', 'anulada') NOT NULL DEFAULT 'generada',
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_cotizaciones_pedidos
      FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
    CONSTRAINT fk_cotizaciones_usuarios
      FOREIGN KEY (usuario_emision_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

CREATE TABLE cotizacion_detalles (
    id CHAR(36) PRIMARY KEY,
    cotizacion_id CHAR(36) NOT NULL,
    pedido_detalle_id CHAR(36) NULL,
    variante_id CHAR(36) NULL,

    codigo_variante VARCHAR(100) NULL,
    descripcion_producto VARCHAR(255) NOT NULL,
    cantidad DECIMAL(12,3) NOT NULL,
    unidad VARCHAR(50) NOT NULL,

    precio_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    precio_medio DECIMAL(12,2) NULL,
    total_sin_igv DECIMAL(12,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_cotizacion_detalles_cotizacion
      FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones_pedido(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_cotizacion_detalles_pedido_detalle
      FOREIGN KEY (pedido_detalle_id) REFERENCES pedido_detalles(id)
      ON DELETE SET NULL,
    CONSTRAINT fk_cotizacion_detalles_variantes
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
      ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE gestion_producto_hoja (
    id CHAR(36) PRIMARY KEY,
    hoja_id CHAR(36) NOT NULL,
    variante_id CHAR(36) NOT NULL,

    cantidad_solicitada_proveedor DECIMAL(12,3) NOT NULL DEFAULT 0,

    estado_gestion ENUM('pendiente', 'solicitado', 'recibido', 'despachado_parcial')
        NOT NULL DEFAULT 'pendiente',

    fecha_marcado DATETIME(3) NULL,
    usuario_marcado_id CHAR(36) NULL,

    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),

    CONSTRAINT fk_gestion_hojas
      FOREIGN KEY (hoja_id) REFERENCES hojas_pedido(id),
    CONSTRAINT fk_gestion_variantes
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id),
    CONSTRAINT fk_gestion_usuarios
      FOREIGN KEY (usuario_marcado_id) REFERENCES usuarios(id),

    UNIQUE KEY uq_gestion_hoja_variante (hoja_id, variante_id)
) ENGINE=InnoDB;

-- ============================================================
-- Sincronización y auditoría
-- ============================================================

CREATE TABLE sync_queue (
    id CHAR(36) PRIMARY KEY,
    entidad VARCHAR(80) NOT NULL,
    entidad_id CHAR(36) NOT NULL,
    accion ENUM('create', 'update', 'delete', 'state_change', 'sync') NOT NULL,
    payload_json JSON NOT NULL,
    estado ENUM('pendiente', 'enviado', 'error') NOT NULL DEFAULT 'pendiente',
    intentos INT NOT NULL DEFAULT 0,
    ultimo_error TEXT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

CREATE TABLE auditoria (
    id CHAR(36) PRIMARY KEY,
    usuario_id CHAR(36) NULL,
    accion VARCHAR(100) NOT NULL,
    entidad VARCHAR(100) NOT NULL,
    entidad_id CHAR(36) NOT NULL,
    detalle_json JSON NULL,
    fecha DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    CONSTRAINT fk_auditoria_usuarios
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- ============================================================
-- Herencia y protección de la clasificación
-- ============================================================

CREATE VIEW vw_categoria_atributos_efectivos AS
WITH RECURSIVE linaje AS (
    SELECT
        id AS categoria_id,
        id AS ancestro_id,
        0 AS nivel_herencia
    FROM categorias

    UNION ALL

    SELECT
        linaje.categoria_id,
        categorias.categoria_padre_id,
        linaje.nivel_herencia + 1
    FROM linaje
    JOIN categorias ON categorias.id = linaje.ancestro_id
    WHERE categorias.categoria_padre_id IS NOT NULL
)
SELECT
    linaje.categoria_id,
    atributos.id AS categoria_atributo_id,
    atributos.categoria_id AS categoria_origen_id,
    atributos.nombre,
    atributos.clave,
    atributos.texto_ayuda,
    atributos.tipo_dato,
    atributos.nivel_captura_recomendado,
    atributos.obligatorio_activacion,
    atributos.mostrar_ficha,
    atributos.filtrable,
    atributos.permite_eje_variante,
    atributos.activo_nuevos_productos,
    atributos.orden,
    atributos.estado,
    linaje.nivel_herencia,
    CASE WHEN linaje.nivel_herencia = 0 THEN 0 ELSE 1 END AS es_heredado
FROM linaje
JOIN categoria_atributos atributos
  ON atributos.categoria_id = linaje.ancestro_id
WHERE atributos.deleted_at IS NULL;

CREATE VIEW vw_categoria_atributos_invalidos AS
SELECT
    atributos.id AS categoria_atributo_id,
    atributos.categoria_id,
    CASE
        WHEN atributos.tipo_dato IN ('lista_unica', 'lista_multiple')
             AND NOT EXISTS (
                 SELECT 1
                 FROM categoria_atributo_opciones opciones
                 WHERE opciones.categoria_atributo_id = atributos.id
                   AND opciones.estado = 1
             )
            THEN 'lista_sin_opciones_activas'
        WHEN atributos.tipo_dato = 'numero_unidad'
             AND NOT EXISTS (
                 SELECT 1
                 FROM categoria_atributo_unidades unidades
                 WHERE unidades.categoria_atributo_id = atributos.id
                   AND unidades.estado = 1
             )
            THEN 'numero_sin_unidades_activas'
        WHEN atributos.tipo_dato = 'numero_unidad'
             AND (
                 SELECT COUNT(*)
                 FROM categoria_atributo_unidades unidades
                 WHERE unidades.categoria_atributo_id = atributos.id
                   AND unidades.estado = 1
                   AND unidades.es_predeterminada = 1
             ) <> 1
            THEN 'unidad_predeterminada_invalida'
    END AS motivo
FROM categoria_atributos atributos
WHERE atributos.deleted_at IS NULL
  AND atributos.estado = 1
  AND atributos.activo_nuevos_productos = 1
  AND (
      (
          atributos.tipo_dato IN ('lista_unica', 'lista_multiple')
          AND NOT EXISTS (
              SELECT 1
              FROM categoria_atributo_opciones opciones
              WHERE opciones.categoria_atributo_id = atributos.id
                AND opciones.estado = 1
          )
      )
      OR
      (
          atributos.tipo_dato = 'numero_unidad'
          AND (
              NOT EXISTS (
                  SELECT 1
                  FROM categoria_atributo_unidades unidades
                  WHERE unidades.categoria_atributo_id = atributos.id
                    AND unidades.estado = 1
              )
              OR (
                  SELECT COUNT(*)
                  FROM categoria_atributo_unidades unidades
                  WHERE unidades.categoria_atributo_id = atributos.id
                    AND unidades.estado = 1
                    AND unidades.es_predeterminada = 1
              ) <> 1
          )
      )
  );

DELIMITER $$

CREATE TRIGGER trg_atributo_cadena_insert
BEFORE INSERT ON categoria_atributos
FOR EACH ROW
BEGIN
    DECLARE colisiones INT DEFAULT 0;

    WITH RECURSIVE
    ancestros(id) AS (
        SELECT NEW.categoria_id
        UNION ALL
        SELECT categorias.categoria_padre_id
        FROM categorias
        JOIN ancestros ON categorias.id = ancestros.id
        WHERE categorias.categoria_padre_id IS NOT NULL
    ),
    descendientes(id) AS (
        SELECT NEW.categoria_id
        UNION ALL
        SELECT categorias.id
        FROM categorias
        JOIN descendientes
          ON categorias.categoria_padre_id = descendientes.id
    ),
    cadena(id) AS (
        SELECT id FROM ancestros
        UNION
        SELECT id FROM descendientes
    )
    SELECT COUNT(*)
    INTO colisiones
    FROM categoria_atributos existentes
    JOIN cadena ON cadena.id = existentes.categoria_id
    WHERE existentes.deleted_at IS NULL
      AND (
          existentes.nombre = NEW.nombre
          OR existentes.clave = NEW.clave
      );

    IF colisiones > 0 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'Nombre o clave repetidos dentro de la cadena de categorías';
    END IF;
END$$

CREATE TRIGGER trg_atributo_cadena_update
BEFORE UPDATE ON categoria_atributos
FOR EACH ROW
BEGIN
    DECLARE colisiones INT DEFAULT 0;

    WITH RECURSIVE
    ancestros(id) AS (
        SELECT NEW.categoria_id
        UNION ALL
        SELECT categorias.categoria_padre_id
        FROM categorias
        JOIN ancestros ON categorias.id = ancestros.id
        WHERE categorias.categoria_padre_id IS NOT NULL
    ),
    descendientes(id) AS (
        SELECT NEW.categoria_id
        UNION ALL
        SELECT categorias.id
        FROM categorias
        JOIN descendientes
          ON categorias.categoria_padre_id = descendientes.id
    ),
    cadena(id) AS (
        SELECT id FROM ancestros
        UNION
        SELECT id FROM descendientes
    )
    SELECT COUNT(*)
    INTO colisiones
    FROM categoria_atributos existentes
    JOIN cadena ON cadena.id = existentes.categoria_id
    WHERE existentes.id <> OLD.id
      AND existentes.deleted_at IS NULL
      AND (
          existentes.nombre = NEW.nombre
          OR existentes.clave = NEW.clave
      );

    IF colisiones > 0 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'Nombre o clave repetidos dentro de la cadena de categorías';
    END IF;
END$$

CREATE TRIGGER trg_unidad_magnitud_insert
BEFORE INSERT ON categoria_atributo_unidades
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM categoria_atributos atributos
        JOIN unidades_medida unidades
          ON unidades.id = NEW.unidad_medida_id
        WHERE atributos.id = NEW.categoria_atributo_id
          AND atributos.tipo_dato = 'numero_unidad'
          AND atributos.magnitud = unidades.magnitud
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'La unidad no es compatible con la magnitud del atributo';
    END IF;
END$$

CREATE TRIGGER trg_unidad_magnitud_update
BEFORE UPDATE ON categoria_atributo_unidades
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM categoria_atributos atributos
        JOIN unidades_medida unidades
          ON unidades.id = NEW.unidad_medida_id
        WHERE atributos.id = NEW.categoria_atributo_id
          AND atributos.tipo_dato = 'numero_unidad'
          AND atributos.magnitud = unidades.magnitud
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'La unidad no es compatible con la magnitud del atributo';
    END IF;
END$$

CREATE TRIGGER trg_atributo_proteger_estructura
BEFORE UPDATE ON categoria_atributos
FOR EACH ROW
BEGIN
    IF (
        NOT (OLD.clave <=> NEW.clave)
        OR NOT (OLD.tipo_dato <=> NEW.tipo_dato)
        OR NOT (OLD.magnitud <=> NEW.magnitud)
    ) AND EXISTS (
        SELECT 1
        FROM producto_atributos valores
        WHERE valores.categoria_atributo_id = OLD.id
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'El tipo, la clave y la magnitud están protegidos porque existen valores';
    END IF;
END$$

CREATE TRIGGER trg_atributo_proteger_eje
BEFORE UPDATE ON categoria_atributos
FOR EACH ROW
BEGIN
    IF (
        (OLD.permite_eje_variante = 1 AND NEW.permite_eje_variante = 0)
        OR (
            OLD.activo_nuevos_productos = 1
            AND NEW.activo_nuevos_productos = 0
        )
        OR (OLD.estado = 1 AND NEW.estado = 0)
    ) AND EXISTS (
        SELECT 1
        FROM producto_familia_ejes ejes
        WHERE ejes.categoria_atributo_id = OLD.id
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'El atributo está siendo utilizado como eje por productos';
    END IF;
END$$

CREATE TRIGGER trg_atributo_no_eliminar_usado
BEFORE DELETE ON categoria_atributos
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM producto_atributos valores
        WHERE valores.categoria_atributo_id = OLD.id
    ) OR EXISTS (
        SELECT 1
        FROM producto_familia_ejes ejes
        WHERE ejes.categoria_atributo_id = OLD.id
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'Un atributo utilizado debe desactivarse; no puede eliminarse';
    END IF;
END$$

CREATE TRIGGER trg_opcion_no_eliminar_usada
BEFORE DELETE ON categoria_atributo_opciones
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM producto_atributo_opciones valores
        WHERE valores.opcion_id = OLD.id
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'Una opción utilizada debe desactivarse; no puede eliminarse';
    END IF;
END$$

CREATE TRIGGER trg_opcion_proteger_codigo
BEFORE UPDATE ON categoria_atributo_opciones
FOR EACH ROW
BEGIN
    IF NOT (OLD.codigo <=> NEW.codigo)
       AND EXISTS (
           SELECT 1
           FROM producto_atributo_opciones valores
           WHERE valores.opcion_id = OLD.id
       )
    THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'El código de una opción utilizada queda protegido';
    END IF;
END$$

CREATE TRIGGER trg_unidad_no_eliminar_usada
BEFORE DELETE ON categoria_atributo_unidades
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM producto_atributos valores
        WHERE valores.unidad_id = OLD.id
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'Una unidad utilizada no puede retirarse del atributo';
    END IF;
END$$

CREATE TRIGGER trg_unidad_proteger_update
BEFORE UPDATE ON categoria_atributo_unidades
FOR EACH ROW
BEGIN
    IF (
        NOT (OLD.unidad_medida_id <=> NEW.unidad_medida_id)
        OR (OLD.estado = 1 AND NEW.estado = 0)
    ) AND EXISTS (
        SELECT 1
        FROM producto_atributos valores
        WHERE valores.unidad_id = OLD.id
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'Una unidad utilizada queda protegida y no puede desactivarse';
    END IF;
END$$

CREATE TRIGGER trg_producto_atributo_normalizar_insert
BEFORE INSERT ON producto_atributos
FOR EACH ROW
BEGIN
    IF NEW.valor_numero IS NULL THEN
        SET NEW.valor_normalizado = NULL;
    ELSEIF NEW.unidad_id IS NULL THEN
        SET NEW.valor_normalizado = NEW.valor_numero;
    ELSE
        SET NEW.valor_normalizado = (
            SELECT
                NEW.valor_numero * unidades.factor_a_base
                + unidades.desplazamiento_a_base
            FROM categoria_atributo_unidades permitidas
            JOIN unidades_medida unidades
              ON unidades.id = permitidas.unidad_medida_id
            WHERE permitidas.id = NEW.unidad_id
              AND permitidas.categoria_atributo_id =
                  NEW.categoria_atributo_id
            LIMIT 1
        );
    END IF;
END$$

CREATE TRIGGER trg_producto_atributo_normalizar_update
BEFORE UPDATE ON producto_atributos
FOR EACH ROW
BEGIN
    IF NEW.valor_numero IS NULL THEN
        SET NEW.valor_normalizado = NULL;
    ELSEIF NEW.unidad_id IS NULL THEN
        SET NEW.valor_normalizado = NEW.valor_numero;
    ELSE
        SET NEW.valor_normalizado = (
            SELECT
                NEW.valor_numero * unidades.factor_a_base
                + unidades.desplazamiento_a_base
            FROM categoria_atributo_unidades permitidas
            JOIN unidades_medida unidades
              ON unidades.id = permitidas.unidad_medida_id
            WHERE permitidas.id = NEW.unidad_id
              AND permitidas.categoria_atributo_id =
                  NEW.categoria_atributo_id
            LIMIT 1
        );
    END IF;
END$$

CREATE TRIGGER trg_familia_eje_insert
BEFORE INSERT ON producto_familia_ejes
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM producto_familias familias
        JOIN vw_categoria_atributos_efectivos efectivos
          ON efectivos.categoria_id = familias.categoria_id
         AND efectivos.categoria_atributo_id =
             NEW.categoria_atributo_id
        JOIN categoria_atributos atributos
          ON atributos.id = efectivos.categoria_atributo_id
        WHERE familias.id = NEW.familia_id
          AND atributos.permite_eje_variante = 1
          AND atributos.activo_nuevos_productos = 1
          AND atributos.estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'El atributo no está habilitado como eje para esta familia';
    END IF;
END$$

CREATE TRIGGER trg_familia_eje_update
BEFORE UPDATE ON producto_familia_ejes
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM producto_familias familias
        JOIN vw_categoria_atributos_efectivos efectivos
          ON efectivos.categoria_id = familias.categoria_id
         AND efectivos.categoria_atributo_id =
             NEW.categoria_atributo_id
        JOIN categoria_atributos atributos
          ON atributos.id = efectivos.categoria_atributo_id
        WHERE familias.id = NEW.familia_id
          AND atributos.permite_eje_variante = 1
          AND atributos.activo_nuevos_productos = 1
          AND atributos.estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'El atributo no está habilitado como eje para esta familia';
    END IF;
END$$

CREATE TRIGGER trg_familia_clasificacion_insert
BEFORE INSERT ON producto_familias
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM marcas
        WHERE marcas.id = NEW.marca_id
          AND marcas.empresa_id = NEW.empresa_id
          AND marcas.estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'La marca no pertenece a la empresa activa indicada';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM marca_categorias
        WHERE marca_categorias.marca_id = NEW.marca_id
          AND marca_categorias.categoria_id = NEW.categoria_id
          AND marca_categorias.estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'La marca no tiene habilitada esta categoría';
    END IF;
END$$

CREATE TRIGGER trg_familia_clasificacion_update
BEFORE UPDATE ON producto_familias
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM marcas
        WHERE marcas.id = NEW.marca_id
          AND marcas.empresa_id = NEW.empresa_id
          AND marcas.estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'La marca no pertenece a la empresa activa indicada';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM marca_categorias
        WHERE marca_categorias.marca_id = NEW.marca_id
          AND marca_categorias.categoria_id = NEW.categoria_id
          AND marca_categorias.estado = 1
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'La marca no tiene habilitada esta categoría';
    END IF;
END$$

CREATE TRIGGER trg_marca_categoria_no_desactivar_usada
BEFORE UPDATE ON marca_categorias
FOR EACH ROW
BEGIN
    IF OLD.estado = 1
       AND NEW.estado = 0
       AND EXISTS (
            SELECT 1
            FROM producto_familias
            WHERE producto_familias.marca_id = OLD.marca_id
              AND producto_familias.categoria_id = OLD.categoria_id
              AND producto_familias.estado = 1
              AND producto_familias.deleted_at IS NULL
       )
    THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'No se puede retirar: existen productos activos usando la relación';
    END IF;
END$$

CREATE TRIGGER trg_marca_categoria_no_eliminar_usada
BEFORE DELETE ON marca_categorias
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM producto_familias
        WHERE producto_familias.marca_id = OLD.marca_id
          AND producto_familias.categoria_id = OLD.categoria_id
          AND producto_familias.deleted_at IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT =
            'No se puede eliminar: la relación tiene historial de productos';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- Vistas para dashboard
-- ============================================================

CREATE VIEW vw_productos_consolidados_hoja AS
SELECT
    hp.id AS hoja_id,
    pv.id AS variante_id,
    e.nombre AS empresa,
    COALESCE(m.nombre, '') AS marca,
    c.nombre AS categoria,
    pf.nombre AS familia,
    pv.codigo AS codigo_variante,
    pv.nombre_comercial AS variante,
    pv.unidad_venta AS unidad,
    SUM(pd.cantidad) AS cantidad_total_solicitada,
    COALESCE(gph.cantidad_solicitada_proveedor, 0) AS cantidad_gestionada,
    GREATEST(SUM(pd.cantidad) - COALESCE(gph.cantidad_solicitada_proveedor, 0), 0) AS cantidad_pendiente,
    COALESCE(gph.estado_gestion, 'pendiente') AS estado_gestion,
    SUM(COALESCE(pd.subtotal_catalogo, 0)) AS subtotal_catalogo,
    SUM(COALESCE(pd.subtotal_final, 0)) AS subtotal_final
FROM hojas_pedido hp
JOIN pedidos pe ON pe.hoja_id = hp.id
JOIN pedido_detalles pd ON pd.pedido_id = pe.id
JOIN producto_variantes pv ON pv.id = pd.variante_id
JOIN producto_familias pf ON pf.id = pv.familia_id
JOIN empresas e ON e.id = pv.empresa_id
LEFT JOIN marcas m ON m.id = pv.marca_id
JOIN categorias c ON c.id = pf.categoria_id
LEFT JOIN gestion_producto_hoja gph
    ON gph.hoja_id = hp.id
   AND gph.variante_id = pv.id
WHERE pe.deleted_at IS NULL
  AND pe.estado <> 'cancelado'
GROUP BY
    hp.id, pv.id, e.nombre, m.nombre, c.nombre, pf.nombre,
    pv.codigo, pv.nombre_comercial, pv.unidad_venta,
    gph.cantidad_solicitada_proveedor, gph.estado_gestion;

CREATE VIEW vw_clientes_por_producto_hoja AS
SELECT
    hp.id AS hoja_id,
    pv.id AS variante_id,
    pe.id AS pedido_id,
    pe.codigo_pedido,
    cl.id AS cliente_id,
    cl.nombre_razon_social AS cliente,
    cl.dni_ruc,
    cl.telefono,
    cl.direccion,
    pd.cantidad,
    pd.unidad,
    pe.fecha,
    pe.estado AS estado_pedido,
    pd.precio_unitario_catalogo,
    pd.precio_unitario_final,
    pd.subtotal_catalogo,
    pd.subtotal_final
FROM hojas_pedido hp
JOIN pedidos pe ON pe.hoja_id = hp.id
JOIN clientes cl ON cl.id = pe.cliente_id
JOIN pedido_detalles pd ON pd.pedido_id = pe.id
JOIN producto_variantes pv ON pv.id = pd.variante_id
WHERE pe.deleted_at IS NULL
  AND pe.estado <> 'cancelado';

-- ============================================================
-- Índices recomendados
-- ============================================================

CREATE INDEX idx_usuarios_rol ON usuarios(rol_id);
CREATE INDEX idx_vendedores_usuario ON vendedores(usuario_id);

CREATE INDEX idx_marcas_empresa ON marcas(empresa_id);
CREATE INDEX idx_categorias_padre ON categorias(categoria_padre_id);

CREATE INDEX idx_familias_empresa_categoria ON producto_familias(empresa_id, categoria_id);
CREATE INDEX idx_familias_marca ON producto_familias(marca_id);
CREATE INDEX idx_familias_nombre ON producto_familias(nombre);

CREATE INDEX idx_variantes_empresa_codigo ON producto_variantes(empresa_id, codigo);
CREATE INDEX idx_variantes_nombre ON producto_variantes(nombre_comercial);
CREATE INDEX idx_variantes_familia ON producto_variantes(familia_id);
CREATE INDEX idx_variantes_marca ON producto_variantes(marca_id);

CREATE INDEX idx_listas_precios_vigencia ON listas_precios(activo, vigencia_desde, vigencia_hasta);
CREATE INDEX idx_precios_lista ON producto_precios(lista_precio_id);
CREATE INDEX idx_precios_variante_presentacion ON producto_precios(variante_id, presentacion_id);
CREATE INDEX idx_precio_rangos_precio ON producto_precio_rangos(producto_precio_id, cantidad_desde);
CREATE INDEX idx_presentaciones_variante ON producto_presentaciones(variante_id);
CREATE INDEX idx_imagenes_variante ON producto_imagenes(variante_id);
CREATE INDEX idx_imagenes_familia ON producto_imagenes(familia_id);
CREATE INDEX idx_imagenes_estado_procesamiento
    ON producto_imagenes(estado_procesamiento);

CREATE INDEX idx_clientes_nombre ON clientes(nombre_razon_social);
CREATE INDEX idx_clientes_documento ON clientes(dni_ruc);
CREATE INDEX idx_clientes_telefono ON clientes(telefono);

CREATE INDEX idx_hojas_vendedor_estado ON hojas_pedido(vendedor_id, estado);
CREATE INDEX idx_pedidos_hoja ON pedidos(hoja_id);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha);

CREATE INDEX idx_detalles_pedido ON pedido_detalles(pedido_id);
CREATE INDEX idx_detalles_variante ON pedido_detalles(variante_id);
CREATE INDEX idx_cotizaciones_pedido ON cotizaciones_pedido(pedido_id);
CREATE INDEX idx_cotizaciones_numero ON cotizaciones_pedido(numero_documento);
CREATE INDEX idx_cotizaciones_fecha ON cotizaciones_pedido(fecha_emision);
CREATE INDEX idx_cotizacion_detalles_cotizacion ON cotizacion_detalles(cotizacion_id);
CREATE INDEX idx_cotizacion_detalles_variante ON cotizacion_detalles(variante_id);
CREATE INDEX idx_gestion_hoja_variante ON gestion_producto_hoja(hoja_id, variante_id);

CREATE INDEX idx_sync_estado ON sync_queue(estado);
CREATE INDEX idx_sync_entidad ON sync_queue(entidad, entidad_id);
CREATE INDEX idx_auditoria_entidad ON auditoria(entidad, entidad_id);
CREATE INDEX idx_auditoria_fecha ON auditoria(fecha);

-- ============================================================
-- Datos base opcionales
-- ============================================================

INSERT INTO roles (id, nombre, descripcion, permisos)
VALUES
('00000000-0000-0000-0000-000000000001', 'administrador', 'Acceso completo al sistema', JSON_OBJECT('all', true)),
('00000000-0000-0000-0000-000000000002', 'vendedor', 'Acceso operativo de ventas', JSON_OBJECT('ventas', true, 'dashboard', true)),
('00000000-0000-0000-0000-000000000003', 'cliente_modo', 'Modo restringido para cliente en tablet', JSON_OBJECT('catalogo', true, 'carrito', true));

INSERT INTO unidades_medida (
    id, codigo, nombre, simbolo, magnitud, factor_a_base,
    desplazamiento_a_base, es_unidad_base
)
VALUES
('unidad-mm', 'mm', 'Milímetro', 'mm', 'Longitud', 1, 0, 1),
('unidad-cm', 'cm', 'Centímetro', 'cm', 'Longitud', 10, 0, 0),
('unidad-in', 'in', 'Pulgada', 'in', 'Longitud', 25.4, 0, 0),
('unidad-g', 'g', 'Gramo', 'g', 'Masa', 1, 0, 1),
('unidad-kg', 'kg', 'Kilogramo', 'kg', 'Masa', 1000, 0, 0);
