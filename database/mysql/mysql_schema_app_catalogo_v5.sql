-- ============================================================
-- App Catálogo Comercial Offline-First
-- Esquema MySQL central
-- Versión: 5.0
-- Descripción:
--   Base central para backend Spring Boot.
--   No incluye tablas catalogos ni catalogo_versiones.
--   Modelo actualizado con empresas, marcas, familias, variantes,
--   atributos, presentaciones, precios, hojas de pedido, descuentos y cotizaciones.
-- ============================================================

CREATE DATABASE IF NOT EXISTS app_catalogo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE app_catalogo;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS vw_clientes_por_producto_hoja;
DROP VIEW IF EXISTS vw_productos_consolidados_hoja;

DROP TABLE IF EXISTS auditoria;
DROP TABLE IF EXISTS sync_queue;
DROP TABLE IF EXISTS gestion_producto_hoja;
DROP TABLE IF EXISTS cotizacion_detalles;
DROP TABLE IF EXISTS cotizaciones_pedido;
DROP TABLE IF EXISTS pedido_detalles;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS hojas_pedido;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS producto_imagenes;
DROP TABLE IF EXISTS producto_precio_rangos;
DROP TABLE IF EXISTS producto_precios;
DROP TABLE IF EXISTS listas_precios;
DROP TABLE IF EXISTS producto_presentaciones;
DROP TABLE IF EXISTS producto_atributos;
DROP TABLE IF EXISTS producto_variantes;
DROP TABLE IF EXISTS producto_familias;
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
    empresa_id CHAR(36) NULL,
    nombre VARCHAR(150) NOT NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    CONSTRAINT fk_marcas_empresas
      FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    UNIQUE KEY uq_marca_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE categorias (
    id CHAR(36) PRIMARY KEY,
    empresa_id CHAR(36) NOT NULL,
    categoria_padre_id CHAR(36) NULL,
    nombre VARCHAR(150) NOT NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at DATETIME(3) NULL,
    CONSTRAINT fk_categorias_empresas
      FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_categorias_padre
      FOREIGN KEY (categoria_padre_id) REFERENCES categorias(id)
) ENGINE=InnoDB;

-- ============================================================
-- Productos: familia, variante, atributos, presentaciones y precios
-- ============================================================

CREATE TABLE producto_familias (
    id CHAR(36) PRIMARY KEY,
    empresa_id CHAR(36) NOT NULL,
    marca_id CHAR(36) NULL,
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
    marca_id CHAR(36) NULL,
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

    UNIQUE KEY uq_empresa_codigo_variante (empresa_id, codigo)
) ENGINE=InnoDB;

CREATE TABLE producto_atributos (
    id CHAR(36) PRIMARY KEY,
    variante_id CHAR(36) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    valor VARCHAR(255) NOT NULL,
    unidad VARCHAR(50) NULL,
    CONSTRAINT fk_atributos_variantes
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
      ON DELETE CASCADE
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

CREATE TABLE producto_imagenes (
    id CHAR(36) PRIMARY KEY,
    variante_id CHAR(36) NULL,
    familia_id CHAR(36) NULL,
    tipo ENUM('thumb', 'detalle', 'referencial') NOT NULL DEFAULT 'detalle',
    ruta_archivo VARCHAR(500) NOT NULL,
    CONSTRAINT fk_imagenes_variantes
      FOREIGN KEY (variante_id) REFERENCES producto_variantes(id)
      ON DELETE CASCADE,
    CONSTRAINT fk_imagenes_familias
      FOREIGN KEY (familia_id) REFERENCES producto_familias(id)
      ON DELETE CASCADE
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
CREATE INDEX idx_categorias_empresa ON categorias(empresa_id);
CREATE INDEX idx_categorias_padre ON categorias(categoria_padre_id);

CREATE INDEX idx_familias_empresa_categoria ON producto_familias(empresa_id, categoria_id);
CREATE INDEX idx_familias_marca ON producto_familias(marca_id);
CREATE INDEX idx_familias_nombre ON producto_familias(nombre);

CREATE INDEX idx_variantes_empresa_codigo ON producto_variantes(empresa_id, codigo);
CREATE INDEX idx_variantes_nombre ON producto_variantes(nombre_comercial);
CREATE INDEX idx_variantes_familia ON producto_variantes(familia_id);
CREATE INDEX idx_variantes_marca ON producto_variantes(marca_id);

CREATE INDEX idx_atributos_variante ON producto_atributos(variante_id);
CREATE INDEX idx_atributos_nombre_valor ON producto_atributos(nombre, valor);
CREATE INDEX idx_listas_precios_vigencia ON listas_precios(activo, vigencia_desde, vigencia_hasta);
CREATE INDEX idx_precios_lista ON producto_precios(lista_precio_id);
CREATE INDEX idx_precios_variante_presentacion ON producto_precios(variante_id, presentacion_id);
CREATE INDEX idx_precio_rangos_precio ON producto_precio_rangos(producto_precio_id, cantidad_desde);
CREATE INDEX idx_presentaciones_variante ON producto_presentaciones(variante_id);
CREATE INDEX idx_imagenes_variante ON producto_imagenes(variante_id);
CREATE INDEX idx_imagenes_familia ON producto_imagenes(familia_id);

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
