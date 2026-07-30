-- ============================================================
-- App Catálogo Comercial Offline-First
-- Esquema SQLite local
-- Versión: 7.0
-- Descripción:
--   Base local para Flutter.
--   No incluye tablas catalogos ni catalogo_versiones.
--   Modelo actualizado con categorías globales, relaciones marca-categoría,
--   atributos heredables, familias, variantes, presentaciones, precios e imágenes,
--   hojas de pedido, descuentos y cotizaciones.
-- ============================================================

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS vw_clientes_por_producto_hoja;
DROP VIEW IF EXISTS vw_productos_consolidados_hoja;
DROP VIEW IF EXISTS vw_categoria_atributos_efectivos;

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
DROP TABLE IF EXISTS producto_variantes;
DROP TABLE IF EXISTS producto_familias;
DROP TABLE IF EXISTS categoria_atributo_unidades;
DROP TABLE IF EXISTS categoria_atributo_opciones;
DROP TABLE IF EXISTS categoria_atributos;
DROP TABLE IF EXISTS marca_categorias;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS marcas;
DROP TABLE IF EXISTS empresas;
DROP TABLE IF EXISTS vendedores;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS roles;

-- ============================================================
-- Seguridad y usuarios
-- ============================================================

CREATE TABLE roles (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT,
    permisos_json TEXT,
    estado INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced'
);

CREATE TABLE usuarios (
    id TEXT PRIMARY KEY,
    rol_id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    usuario TEXT NOT NULL UNIQUE,
    clave_hash TEXT NOT NULL,
    estado INTEGER NOT NULL DEFAULT 1,
    ultimo_acceso TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (rol_id) REFERENCES roles(id)
);

CREATE TABLE vendedores (
    id TEXT PRIMARY KEY,
    usuario_id TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    documento TEXT,
    telefono TEXT,
    estado INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- ============================================================
-- Empresas, marcas y clasificación
-- ============================================================

CREATE TABLE empresas (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    ruc TEXT,
    telefono TEXT,
    direccion TEXT,
    estado INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced'
);

CREATE TABLE marcas (
    id TEXT PRIMARY KEY,
    empresa_id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    estado INTEGER NOT NULL DEFAULT 1 CHECK (estado IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    UNIQUE (empresa_id, nombre)
);

-- Las categorías son globales: no contienen empresa_id.
CREATE TABLE categorias (
    id TEXT PRIMARY KEY,
    categoria_padre_id TEXT,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    estado INTEGER NOT NULL DEFAULT 1 CHECK (estado IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (categoria_padre_id) REFERENCES categorias(id),
    CHECK (categoria_padre_id IS NULL OR categoria_padre_id <> id)
);

-- Una marca puede usar muchas categorías globales y una categoría muchas marcas.
CREATE TABLE marca_categorias (
    marca_id TEXT NOT NULL,
    categoria_id TEXT NOT NULL,
    estado INTEGER NOT NULL DEFAULT 1 CHECK (estado IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    PRIMARY KEY (marca_id, categoria_id),
    FOREIGN KEY (marca_id) REFERENCES marcas(id),
    FOREIGN KEY (categoria_id) REFERENCES categorias(id)
);

-- Definición estable de los datos técnicos solicitados por una categoría.
-- Los atributos de ancestros se heredan dinámicamente; no se duplican.
CREATE TABLE categoria_atributos (
    id TEXT PRIMARY KEY,
    categoria_id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    tipo_dato TEXT NOT NULL
        CHECK (tipo_dato IN ('texto', 'numero', 'lista', 'booleano', 'fecha')),
    obligatorio INTEGER NOT NULL DEFAULT 0 CHECK (obligatorio IN (0, 1)),
    filtrable INTEGER NOT NULL DEFAULT 0 CHECK (filtrable IN (0, 1)),
    genera_variantes INTEGER NOT NULL DEFAULT 0
        CHECK (genera_variantes IN (0, 1)),
    seleccion_multiple INTEGER NOT NULL DEFAULT 0
        CHECK (seleccion_multiple IN (0, 1)),
    estado INTEGER NOT NULL DEFAULT 1 CHECK (estado IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (categoria_id) REFERENCES categorias(id),
    UNIQUE (categoria_id, nombre),
    CHECK (seleccion_multiple = 0 OR tipo_dato = 'lista')
);

CREATE TABLE categoria_atributo_opciones (
    id TEXT PRIMARY KEY,
    categoria_atributo_id TEXT NOT NULL,
    valor TEXT NOT NULL,
    orden INTEGER NOT NULL DEFAULT 0 CHECK (orden >= 0),
    estado INTEGER NOT NULL DEFAULT 1 CHECK (estado IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (categoria_atributo_id)
        REFERENCES categoria_atributos(id),
    UNIQUE (categoria_atributo_id, valor),
    UNIQUE (id, categoria_atributo_id)
);

CREATE TABLE categoria_atributo_unidades (
    id TEXT PRIMARY KEY,
    categoria_atributo_id TEXT NOT NULL,
    codigo TEXT NOT NULL,
    nombre TEXT NOT NULL,
    orden INTEGER NOT NULL DEFAULT 0 CHECK (orden >= 0),
    estado INTEGER NOT NULL DEFAULT 1 CHECK (estado IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (categoria_atributo_id)
        REFERENCES categoria_atributos(id),
    UNIQUE (categoria_atributo_id, codigo),
    UNIQUE (id, categoria_atributo_id)
);

-- ============================================================
-- Productos: familia, variante, atributos, presentaciones y precios
-- ============================================================

CREATE TABLE producto_familias (
    id TEXT PRIMARY KEY,
    empresa_id TEXT NOT NULL,
    marca_id TEXT NOT NULL,
    categoria_id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    tipo_producto TEXT,
    estado INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    FOREIGN KEY (marca_id) REFERENCES marcas(id),
    FOREIGN KEY (categoria_id) REFERENCES categorias(id)
);

CREATE TABLE producto_variantes (
    id TEXT PRIMARY KEY,
    familia_id TEXT NOT NULL,
    empresa_id TEXT NOT NULL,
    marca_id TEXT NOT NULL,
    codigo TEXT,
    nombre_comercial TEXT NOT NULL,
    descripcion_corta TEXT,
    unidad_venta TEXT NOT NULL DEFAULT 'UND',

    estado INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'synced',

    FOREIGN KEY (familia_id) REFERENCES producto_familias(id),
    FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    FOREIGN KEY (marca_id) REFERENCES marcas(id),

    UNIQUE (empresa_id, codigo),

    -- Necesaria para validar que una excepción use una imagen de su familia.
    UNIQUE (id, familia_id)
);

-- Valor concreto de una definición de atributo. Puede ser compartido por la
-- familia o ser una excepción/valor de variante, nunca ambos a la vez.
CREATE TABLE producto_atributos (
    id TEXT PRIMARY KEY,
    categoria_atributo_id TEXT NOT NULL,
    familia_id TEXT,
    variante_id TEXT,
    valor_texto TEXT,
    valor_numero REAL,
    valor_booleano INTEGER CHECK (valor_booleano IN (0, 1)),
    valor_fecha TEXT,
    unidad_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    FOREIGN KEY (categoria_atributo_id)
        REFERENCES categoria_atributos(id),
    FOREIGN KEY (familia_id)
        REFERENCES producto_familias(id) ON DELETE CASCADE,
    FOREIGN KEY (variante_id)
        REFERENCES producto_variantes(id) ON DELETE CASCADE,
    FOREIGN KEY (unidad_id, categoria_atributo_id)
        REFERENCES categoria_atributo_unidades(id, categoria_atributo_id),
    CHECK ((familia_id IS NOT NULL) <> (variante_id IS NOT NULL)),
    UNIQUE (id, categoria_atributo_id)
);

-- Las selecciones simples o múltiples apuntan a opciones definidas, nunca a
-- nombres escritos libremente.
CREATE TABLE producto_atributo_opciones (
    producto_atributo_id TEXT NOT NULL,
    categoria_atributo_id TEXT NOT NULL,
    opcion_id TEXT NOT NULL,
    PRIMARY KEY (producto_atributo_id, opcion_id),
    FOREIGN KEY (producto_atributo_id, categoria_atributo_id)
        REFERENCES producto_atributos(id, categoria_atributo_id)
        ON DELETE CASCADE,
    FOREIGN KEY (opcion_id, categoria_atributo_id)
        REFERENCES categoria_atributo_opciones(id, categoria_atributo_id)
);

CREATE TABLE producto_presentaciones (
    id TEXT PRIMARY KEY,
    variante_id TEXT NOT NULL,
    nombre TEXT NOT NULL,
    cantidad REAL NOT NULL DEFAULT 1,
    unidad TEXT NOT NULL,
    es_venta_minima INTEGER NOT NULL DEFAULT 0,
    es_empaque INTEGER NOT NULL DEFAULT 0,
    es_caja INTEGER NOT NULL DEFAULT 0,
    descripcion TEXT,
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id) ON DELETE CASCADE,
    UNIQUE (id, variante_id)
);

-- Una lista concentra moneda, tratamiento de IGV y vigencia.
-- Los importes de producto_precios heredan esta configuración.
CREATE TABLE listas_precios (
    id TEXT PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    moneda TEXT NOT NULL DEFAULT 'PEN'
        CHECK (moneda IN ('PEN', 'USD', 'EUR')),
    incluye_igv INTEGER NOT NULL DEFAULT 1
        CHECK (incluye_igv IN (0, 1)),
    vigencia_desde TEXT NOT NULL,
    vigencia_hasta TEXT,
    activo INTEGER NOT NULL DEFAULT 1
        CHECK (activo IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',
    CHECK (
        vigencia_hasta IS NULL
        OR vigencia_hasta >= vigencia_desde
    )
);

-- Cada registro representa una decisión completa para:
-- lista + variante + presentación vendible.
-- "Sin configurar" es la ausencia de este registro.
CREATE TABLE producto_precios (
    id TEXT PRIMARY KEY,
    lista_precio_id TEXT NOT NULL,
    variante_id TEXT NOT NULL,
    presentacion_id TEXT NOT NULL,
    configuracion TEXT NOT NULL
        CHECK (
            configuracion IN (
                'precio_fijo',
                'por_cantidad',
                'por_cotizar'
            )
        ),
    precio_fijo REAL,
    activo INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',

    FOREIGN KEY (lista_precio_id)
        REFERENCES listas_precios(id) ON DELETE CASCADE,
    FOREIGN KEY (presentacion_id, variante_id)
        REFERENCES producto_presentaciones(id, variante_id)
        ON DELETE CASCADE,

    UNIQUE (lista_precio_id, variante_id, presentacion_id),

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
);

-- Solo se crean rangos cuando configuracion = 'por_cantidad'.
-- La aplicación valida continuidad y ausencia de superposiciones.
CREATE TABLE producto_precio_rangos (
    id TEXT PRIMARY KEY,
    producto_precio_id TEXT NOT NULL,
    cantidad_desde REAL NOT NULL,
    cantidad_hasta REAL,
    precio_presentacion REAL NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'synced',

    FOREIGN KEY (producto_precio_id)
        REFERENCES producto_precios(id) ON DELETE CASCADE,

    UNIQUE (producto_precio_id, cantidad_desde),

    CHECK (cantidad_desde > 0),
    CHECK (
        cantidad_hasta IS NULL
        OR cantidad_hasta >= cantidad_desde
    ),
    CHECK (precio_presentacion >= 0)
);

-- ============================================================
-- Imágenes, galería familiar y excepciones por variante
-- ============================================================
--
-- La galería se guarda una sola vez con familia_id.
-- Una imagen específica usa variante_id.
-- La restricción XOR impide que una imagen pertenezca a ambas.
CREATE TABLE producto_imagenes (
    id TEXT PRIMARY KEY,
    familia_id TEXT,
    variante_id TEXT,

    tipo TEXT NOT NULL DEFAULT 'detalle'
        CHECK (tipo IN ('thumb', 'detalle', 'referencial')),
    etiqueta TEXT NOT NULL DEFAULT 'Detalle',
    es_principal INTEGER NOT NULL DEFAULT 0
        CHECK (es_principal IN (0, 1)),
    orden INTEGER NOT NULL DEFAULT 0
        CHECK (orden >= 0),

    path_archivo TEXT NOT NULL,
    nombre_archivo TEXT NOT NULL,
    mime_type TEXT NOT NULL
        CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
    tamano_bytes INTEGER NOT NULL
        CHECK (tamano_bytes > 0),
    ancho_px INTEGER
        CHECK (ancho_px IS NULL OR ancho_px > 0),
    alto_px INTEGER
        CHECK (alto_px IS NULL OR alto_px > 0),
    checksum_sha256 TEXT,

    estado_procesamiento TEXT NOT NULL DEFAULT 'lista'
        CHECK (
            estado_procesamiento IN ('procesando', 'lista', 'error')
        ),
    error_procesamiento TEXT,

    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (sync_status IN ('pending', 'synced', 'error')),

    FOREIGN KEY (variante_id)
        REFERENCES producto_variantes(id) ON DELETE CASCADE,
    FOREIGN KEY (familia_id)
        REFERENCES producto_familias(id) ON DELETE CASCADE,

    CHECK (
        (familia_id IS NOT NULL AND variante_id IS NULL)
        OR
        (familia_id IS NULL AND variante_id IS NOT NULL)
    ),

    -- Claves candidatas para las referencias compuestas de excepciones.
    UNIQUE (id, familia_id),
    UNIQUE (id, variante_id)
);

-- La ausencia de una fila significa "hereda la principal familiar".
-- Una fila puede apuntar a otra imagen de la galería de la misma familia
-- o a una imagen específica de la misma variante, nunca a las dos.
-- Si una imagen se elimina de forma lógica, el repositorio debe borrar su
-- excepción en la misma transacción; ON DELETE CASCADE cubre el borrado físico.
CREATE TABLE producto_imagen_excepciones (
    variante_id TEXT PRIMARY KEY,
    familia_id TEXT NOT NULL,
    imagen_familia_id TEXT,
    imagen_variante_id TEXT,

    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (sync_status IN ('pending', 'synced', 'error')),

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

    FOREIGN KEY (variante_id, familia_id)
        REFERENCES producto_variantes(id, familia_id)
        ON DELETE CASCADE,
    FOREIGN KEY (imagen_familia_id, familia_id)
        REFERENCES producto_imagenes(id, familia_id)
        ON DELETE CASCADE,
    FOREIGN KEY (imagen_variante_id, variante_id)
        REFERENCES producto_imagenes(id, variante_id)
        ON DELETE CASCADE
);

-- ============================================================
-- Clientes
-- ============================================================

CREATE TABLE clientes (
    id TEXT PRIMARY KEY,
    nombre_razon_social TEXT NOT NULL,
    dni_ruc TEXT,
    telefono TEXT NOT NULL,
    direccion TEXT NOT NULL,
    referencia TEXT,
    foto_referencia TEXT,
    estado INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'pending',
    UNIQUE (dni_ruc)
);

-- ============================================================
-- Hojas de pedido, pedidos y detalles
-- ============================================================

CREATE TABLE hojas_pedido (
    id TEXT PRIMARY KEY,
    codigo_hoja TEXT NOT NULL UNIQUE,
    vendedor_id TEXT NOT NULL,

    fecha_creacion TEXT NOT NULL,
    fecha_cierre TEXT,

    estado TEXT NOT NULL DEFAULT 'abierta'
        CHECK (estado IN ('abierta', 'completada')),

    total_estimado_catalogo REAL NOT NULL DEFAULT 0,
    total_estimado_final REAL NOT NULL DEFAULT 0,

    cantidad_pedidos INTEGER NOT NULL DEFAULT 0,
    cantidad_productos REAL NOT NULL DEFAULT 0,

    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',

    FOREIGN KEY (vendedor_id) REFERENCES vendedores(id)
);

CREATE TABLE pedidos (
    id TEXT PRIMARY KEY,
    codigo_pedido TEXT NOT NULL UNIQUE,

    hoja_id TEXT NOT NULL,
    cliente_id TEXT NOT NULL,
    vendedor_id TEXT NOT NULL,

    fecha TEXT NOT NULL,

    estado TEXT NOT NULL DEFAULT 'pendiente'
        CHECK (estado IN ('pendiente', 'en_proceso', 'listo_para_entregar', 'entregado', 'cancelado')),

    total_catalogo REAL NOT NULL DEFAULT 0,
    total_rebajado_items REAL NOT NULL DEFAULT 0,

    descuento_global_tipo TEXT NOT NULL DEFAULT 'ninguno'
        CHECK (descuento_global_tipo IN ('ninguno', 'monto', 'porcentaje')),

    descuento_global_valor REAL NOT NULL DEFAULT 0,

    total_final REAL NOT NULL DEFAULT 0,

    tiene_productos_sin_precio INTEGER NOT NULL DEFAULT 0,
    total_es_parcial INTEGER NOT NULL DEFAULT 0,

    precio_editado INTEGER NOT NULL DEFAULT 0,
    motivo_descuento TEXT,

    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'pending',

    FOREIGN KEY (hoja_id) REFERENCES hojas_pedido(id),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (vendedor_id) REFERENCES vendedores(id)
);

CREATE TABLE pedido_detalles (
    id TEXT PRIMARY KEY,
    pedido_id TEXT NOT NULL,
    variante_id TEXT NOT NULL,

    cantidad REAL NOT NULL,
    unidad TEXT NOT NULL,

    precio_unitario_catalogo REAL,
    precio_unitario_final REAL,

    subtotal_catalogo REAL,
    subtotal_final REAL,

    descuento_item_tipo TEXT NOT NULL DEFAULT 'ninguno'
        CHECK (descuento_item_tipo IN ('ninguno', 'monto', 'porcentaje', 'precio_manual')),

    descuento_item_valor REAL NOT NULL DEFAULT 0,

    sin_precio INTEGER NOT NULL DEFAULT 0,

    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',

    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
);

-- ============================================================
-- Cotizaciones / presupuestos exportados
-- ============================================================

CREATE TABLE cotizaciones_pedido (
    id TEXT PRIMARY KEY,
    pedido_id TEXT NOT NULL,
    numero_documento TEXT NOT NULL UNIQUE,
    tipo_documento TEXT NOT NULL DEFAULT 'cotizacion'
        CHECK (tipo_documento IN ('cotizacion', 'presupuesto', 'proforma')),
    fecha_emision TEXT NOT NULL,
    usuario_emision_id TEXT,

    cliente_nombre_snapshot TEXT NOT NULL,
    cliente_documento_snapshot TEXT,
    cliente_telefono_snapshot TEXT,
    cliente_direccion_snapshot TEXT,

    moneda TEXT NOT NULL DEFAULT 'PEN',
    subtotal_items REAL NOT NULL DEFAULT 0,
    descuento_total REAL NOT NULL DEFAULT 0,
    total_sin_igv REAL NOT NULL DEFAULT 0,
    igv_porcentaje REAL NOT NULL DEFAULT 18.00,
    igv_total REAL NOT NULL DEFAULT 0,
    total_final REAL NOT NULL DEFAULT 0,

    archivo_ruta TEXT,
    estado TEXT NOT NULL DEFAULT 'generada'
        CHECK (estado IN ('generada', 'anulada')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',

    FOREIGN KEY (pedido_id) REFERENCES pedidos(id),
    FOREIGN KEY (usuario_emision_id) REFERENCES usuarios(id)
);

CREATE TABLE cotizacion_detalles (
    id TEXT PRIMARY KEY,
    cotizacion_id TEXT NOT NULL,
    pedido_detalle_id TEXT,
    variante_id TEXT,

    codigo_variante TEXT,
    descripcion_producto TEXT NOT NULL,
    cantidad REAL NOT NULL,
    unidad TEXT NOT NULL,

    precio_unitario REAL NOT NULL DEFAULT 0,
    precio_medio REAL,
    total_sin_igv REAL NOT NULL DEFAULT 0,
    subtotal REAL NOT NULL DEFAULT 0,
    total REAL NOT NULL DEFAULT 0,

    created_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',

    FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones_pedido(id) ON DELETE CASCADE,
    FOREIGN KEY (pedido_detalle_id) REFERENCES pedido_detalles(id) ON DELETE SET NULL,
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id) ON DELETE SET NULL
);

CREATE TABLE gestion_producto_hoja (
    id TEXT PRIMARY KEY,
    hoja_id TEXT NOT NULL,
    variante_id TEXT NOT NULL,

    cantidad_solicitada_proveedor REAL NOT NULL DEFAULT 0,

    estado_gestion TEXT NOT NULL DEFAULT 'pendiente'
        CHECK (estado_gestion IN ('pendiente', 'solicitado', 'recibido', 'despachado_parcial')),

    fecha_marcado TEXT,
    usuario_marcado_id TEXT,

    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',

    FOREIGN KEY (hoja_id) REFERENCES hojas_pedido(id),
    FOREIGN KEY (variante_id) REFERENCES producto_variantes(id),
    FOREIGN KEY (usuario_marcado_id) REFERENCES usuarios(id),

    UNIQUE (hoja_id, variante_id)
);

-- ============================================================
-- Sincronización y auditoría
-- ============================================================

CREATE TABLE sync_queue (
    id TEXT PRIMARY KEY,
    entidad TEXT NOT NULL,
    entidad_id TEXT NOT NULL,
    accion TEXT NOT NULL
        CHECK (accion IN ('create', 'update', 'delete', 'state_change', 'sync')),
    payload_json TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'pendiente'
        CHECK (estado IN ('pendiente', 'enviado', 'error')),
    intentos INTEGER NOT NULL DEFAULT 0,
    ultimo_error TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE auditoria (
    id TEXT PRIMARY KEY,
    usuario_id TEXT,
    accion TEXT NOT NULL,
    entidad TEXT NOT NULL,
    entidad_id TEXT NOT NULL,
    detalle_json TEXT,
    fecha TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- ============================================================
-- Herencia y protección de la clasificación
-- ============================================================

-- Para cada categoría devuelve sus atributos propios y los heredados.
-- nivel_herencia = 0 significa propio; valores mayores provienen de ancestros.
CREATE VIEW vw_categoria_atributos_efectivos AS
WITH RECURSIVE linaje(categoria_id, ancestro_id, nivel_herencia) AS (
    SELECT id, id, 0
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
    atributos.tipo_dato,
    atributos.obligatorio,
    atributos.filtrable,
    atributos.genera_variantes,
    atributos.seleccion_multiple,
    atributos.estado,
    linaje.nivel_herencia,
    CASE WHEN linaje.nivel_herencia = 0 THEN 0 ELSE 1 END AS es_heredado
FROM linaje
JOIN categoria_atributos atributos
    ON atributos.categoria_id = linaje.ancestro_id
WHERE atributos.deleted_at IS NULL;

-- Impide registrar una familia con una empresa distinta de la empresa de su
-- marca o con una categoría que la marca no tenga habilitada.
CREATE TRIGGER trg_familia_clasificacion_insert
BEFORE INSERT ON producto_familias
BEGIN
    SELECT CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM marcas
            WHERE marcas.id = NEW.marca_id
              AND marcas.empresa_id = NEW.empresa_id
              AND marcas.estado = 1
        )
        THEN RAISE(ABORT, 'La marca no pertenece a la empresa activa indicada')
    END;

    SELECT CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM marca_categorias
            WHERE marca_categorias.marca_id = NEW.marca_id
              AND marca_categorias.categoria_id = NEW.categoria_id
              AND marca_categorias.estado = 1
        )
        THEN RAISE(ABORT, 'La marca no tiene habilitada esta categoría')
    END;
END;

CREATE TRIGGER trg_familia_clasificacion_update
BEFORE UPDATE OF empresa_id, marca_id, categoria_id ON producto_familias
BEGIN
    SELECT CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM marcas
            WHERE marcas.id = NEW.marca_id
              AND marcas.empresa_id = NEW.empresa_id
              AND marcas.estado = 1
        )
        THEN RAISE(ABORT, 'La marca no pertenece a la empresa activa indicada')
    END;

    SELECT CASE
        WHEN NOT EXISTS (
            SELECT 1
            FROM marca_categorias
            WHERE marca_categorias.marca_id = NEW.marca_id
              AND marca_categorias.categoria_id = NEW.categoria_id
              AND marca_categorias.estado = 1
        )
        THEN RAISE(ABORT, 'La marca no tiene habilitada esta categoría')
    END;
END;

CREATE TRIGGER trg_marca_categoria_no_desactivar_usada
BEFORE UPDATE OF estado ON marca_categorias
WHEN OLD.estado = 1 AND NEW.estado = 0
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM producto_familias
            WHERE producto_familias.marca_id = OLD.marca_id
              AND producto_familias.categoria_id = OLD.categoria_id
              AND producto_familias.estado = 1
              AND producto_familias.deleted_at IS NULL
        )
        THEN RAISE(
            ABORT,
            'No se puede retirar: existen productos activos usando la relación'
        )
    END;
END;

CREATE TRIGGER trg_marca_categoria_no_eliminar_usada
BEFORE DELETE ON marca_categorias
BEGIN
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM producto_familias
            WHERE producto_familias.marca_id = OLD.marca_id
              AND producto_familias.categoria_id = OLD.categoria_id
              AND producto_familias.deleted_at IS NULL
        )
        THEN RAISE(
            ABORT,
            'No se puede eliminar: la relación tiene historial de productos'
        )
    END;
END;

-- ============================================================
-- Vistas para dashboard
-- ============================================================

CREATE VIEW vw_productos_consolidados_hoja AS
SELECT
    hp.id AS hoja_id,
    pv.id AS variante_id,
    e.nombre AS empresa,
    IFNULL(m.nombre, '') AS marca,
    c.nombre AS categoria,
    pf.nombre AS familia,
    pv.codigo AS codigo_variante,
    pv.nombre_comercial AS variante,
    pv.unidad_venta AS unidad,
    SUM(pd.cantidad) AS cantidad_total_solicitada,
    IFNULL(gph.cantidad_solicitada_proveedor, 0) AS cantidad_gestionada,
    CASE
        WHEN SUM(pd.cantidad) - IFNULL(gph.cantidad_solicitada_proveedor, 0) < 0
        THEN 0
        ELSE SUM(pd.cantidad) - IFNULL(gph.cantidad_solicitada_proveedor, 0)
    END AS cantidad_pendiente,
    IFNULL(gph.estado_gestion, 'pendiente') AS estado_gestion,
    SUM(IFNULL(pd.subtotal_catalogo, 0)) AS subtotal_catalogo,
    SUM(IFNULL(pd.subtotal_final, 0)) AS subtotal_final
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
CREATE INDEX idx_marca_categorias_categoria
    ON marca_categorias(categoria_id, estado);
CREATE INDEX idx_categoria_atributos_categoria
    ON categoria_atributos(categoria_id, estado);
CREATE INDEX idx_categoria_atributo_opciones_atributo
    ON categoria_atributo_opciones(categoria_atributo_id, estado, orden);
CREATE INDEX idx_categoria_atributo_unidades_atributo
    ON categoria_atributo_unidades(categoria_atributo_id, estado, orden);

-- Un nombre de categoría es único dentro del mismo padre.
CREATE UNIQUE INDEX uq_categoria_nombre_raiz
    ON categorias(nombre COLLATE NOCASE)
    WHERE categoria_padre_id IS NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX uq_categoria_nombre_hija
    ON categorias(categoria_padre_id, nombre COLLATE NOCASE)
    WHERE categoria_padre_id IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX idx_familias_empresa_categoria ON producto_familias(empresa_id, categoria_id);
CREATE INDEX idx_familias_marca ON producto_familias(marca_id);
CREATE INDEX idx_familias_nombre ON producto_familias(nombre);

CREATE INDEX idx_variantes_empresa_codigo ON producto_variantes(empresa_id, codigo);
CREATE INDEX idx_variantes_nombre ON producto_variantes(nombre_comercial);
CREATE INDEX idx_variantes_familia ON producto_variantes(familia_id);
CREATE INDEX idx_variantes_marca ON producto_variantes(marca_id);

CREATE INDEX idx_atributos_definicion
    ON producto_atributos(categoria_atributo_id);
CREATE INDEX idx_atributos_familia
    ON producto_atributos(familia_id);
CREATE INDEX idx_atributos_variante
    ON producto_atributos(variante_id);
CREATE INDEX idx_producto_atributo_opciones_opcion
    ON producto_atributo_opciones(opcion_id);

-- Una familia o variante tiene como máximo un valor escalar por definición.
CREATE UNIQUE INDEX uq_producto_atributo_familia
    ON producto_atributos(familia_id, categoria_atributo_id)
    WHERE familia_id IS NOT NULL;
CREATE UNIQUE INDEX uq_producto_atributo_variante
    ON producto_atributos(variante_id, categoria_atributo_id)
    WHERE variante_id IS NOT NULL;
CREATE INDEX idx_listas_precios_vigencia ON listas_precios(activo, vigencia_desde, vigencia_hasta);
CREATE INDEX idx_precios_lista ON producto_precios(lista_precio_id);
CREATE INDEX idx_precios_variante_presentacion ON producto_precios(variante_id, presentacion_id);
CREATE INDEX idx_precio_rangos_precio ON producto_precio_rangos(producto_precio_id, cantidad_desde);
CREATE INDEX idx_presentaciones_variante ON producto_presentaciones(variante_id);
CREATE INDEX idx_imagenes_variante ON producto_imagenes(variante_id);
CREATE INDEX idx_imagenes_familia ON producto_imagenes(familia_id);
CREATE INDEX idx_imagenes_estado_sync
    ON producto_imagenes(estado_procesamiento, sync_status);
CREATE INDEX idx_imagen_excepciones_familia
    ON producto_imagen_excepciones(familia_id);
CREATE INDEX idx_imagen_excepciones_imagen_familia
    ON producto_imagen_excepciones(imagen_familia_id);
CREATE INDEX idx_imagen_excepciones_imagen_variante
    ON producto_imagen_excepciones(imagen_variante_id);

-- Como máximo una principal y una posición activa por propietario.
-- "Al menos una principal" se valida al activar en el paso 7, no al guardar
-- el borrador.
CREATE UNIQUE INDEX uq_imagen_principal_familia
    ON producto_imagenes(familia_id)
    WHERE (
        familia_id IS NOT NULL
        AND es_principal = 1
        AND deleted_at IS NULL
    );
CREATE UNIQUE INDEX uq_imagen_principal_variante
    ON producto_imagenes(variante_id)
    WHERE (
        variante_id IS NOT NULL
        AND es_principal = 1
        AND deleted_at IS NULL
    );
CREATE UNIQUE INDEX uq_imagen_orden_familia
    ON producto_imagenes(familia_id, orden)
    WHERE familia_id IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX uq_imagen_orden_variante
    ON producto_imagenes(variante_id, orden)
    WHERE variante_id IS NOT NULL AND deleted_at IS NULL;

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

INSERT INTO roles (id, nombre, descripcion, permisos_json, created_at, updated_at)
VALUES
('00000000-0000-0000-0000-000000000001', 'administrador', 'Acceso completo al sistema', '{"all": true}', datetime('now'), datetime('now')),
('00000000-0000-0000-0000-000000000002', 'vendedor', 'Acceso operativo de ventas', '{"ventas": true, "dashboard": true}', datetime('now'), datetime('now')),
('00000000-0000-0000-0000-000000000003', 'cliente_modo', 'Modo restringido para cliente en tablet', '{"catalogo": true, "carrito": true}', datetime('now'), datetime('now'));
