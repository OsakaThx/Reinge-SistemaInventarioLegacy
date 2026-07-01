-- =============================================================================
-- migracion_001_normalizar_categorias.sql
-- Laboratorio 7 - Parte D: Migracion de esquema en T-SQL
-- -----------------------------------------------------------------------------
-- ESCENARIO
-- En el esquema legado (setup_database.sql) la categoria de un producto se
-- guarda como una clave foranea Productos.CategoriaId -> Categorias(Id), pero
-- existen instalaciones antiguas donde la categoria estaba como TEXTO LIBRE en
-- una columna Productos.Categoria (desnormalizada). Esta migracion normaliza
-- ese caso: garantiza la tabla Categorias, agrega/rellena CategoriaId a partir
-- del texto libre (si existe) y declara la clave foranea.
--
-- PROPIEDADES
--   * Idempotente : puede ejecutarse varias veces sin romper nada.
--   * Transaccional: SET XACT_ABORT ON + BEGIN/COMMIT TRAN (todo o nada).
--   * No destructiva: la columna de texto Categoria (si existe) NUNCA se borra
--                     en esta fase, de modo que ningun dato se pierde.
--
-- Ejecutar sobre la base InventarioLegacyDB.
-- =============================================================================
USE InventarioLegacyDB;
GO

SET XACT_ABORT ON;
BEGIN TRAN;

-- 1) Garantizar la tabla Categorias (idempotente)
IF OBJECT_ID('dbo.Categorias', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Categorias (
        Id     INT IDENTITY(1,1) PRIMARY KEY,
        Nombre VARCHAR(100) NOT NULL
    );
END;

-- Garantizar unicidad del nombre de categoria (idempotente)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Categorias_Nombre')
   AND COL_LENGTH('dbo.Categorias', 'Nombre') IS NOT NULL
BEGIN
    CREATE UNIQUE INDEX UQ_Categorias_Nombre ON dbo.Categorias(Nombre);
END;

-- 2) Si existe la columna de texto libre Categoria, poblar Categorias con sus
--    valores distintos que aun no esten registrados.
IF COL_LENGTH('dbo.Productos', 'Categoria') IS NOT NULL
BEGIN
    INSERT INTO dbo.Categorias (Nombre)
    SELECT DISTINCT LTRIM(RTRIM(p.Categoria))
    FROM   dbo.Productos p
    WHERE  p.Categoria IS NOT NULL
      AND  LTRIM(RTRIM(p.Categoria)) <> ''
      AND  NOT EXISTS (SELECT 1 FROM dbo.Categorias c
                       WHERE c.Nombre = LTRIM(RTRIM(p.Categoria)));
END;

-- 3) Garantizar la columna clave foranea CategoriaId (idempotente)
IF COL_LENGTH('dbo.Productos', 'CategoriaId') IS NULL
    ALTER TABLE dbo.Productos ADD CategoriaId INT NULL;
GO

-- 4) Vincular cada producto con su categoria normalizada a partir del texto
--    libre, solo para los que aun no tienen CategoriaId.
IF COL_LENGTH('dbo.Productos', 'Categoria') IS NOT NULL
BEGIN
    UPDATE p
    SET    p.CategoriaId = c.Id
    FROM   dbo.Productos p
    JOIN   dbo.Categorias c ON c.Nombre = LTRIM(RTRIM(p.Categoria))
    WHERE  p.CategoriaId IS NULL;
END;
GO

-- 5) Declarar la relacion Productos -> Categorias (idempotente)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Productos_Categorias')
    ALTER TABLE dbo.Productos
    ADD CONSTRAINT FK_Productos_Categorias
        FOREIGN KEY (CategoriaId) REFERENCES dbo.Categorias(Id);

COMMIT TRAN;
GO

PRINT 'Migracion 001 (normalizar categorias) aplicada correctamente.';
GO

-- =============================================================================
-- VISTA DE COMPATIBILIDAD
-- -----------------------------------------------------------------------------
-- Conserva la "forma antigua" (Categoria como texto) para que el codigo legado
-- que hacia SELECT ... FROM Productos siga funcionando mientras se migra la
-- aplicacion. Expone tambien CategoriaId (forma nueva).
-- =============================================================================
CREATE OR ALTER VIEW dbo.vw_Productos AS
SELECT  p.Id,
        p.Codigo,
        p.Nombre,
        c.Nombre AS Categoria,   -- forma antigua: nombre de la categoria
        p.PrecioCompra,
        p.PrecioVenta,
        p.Stock,
        p.CategoriaId            -- forma nueva: clave foranea
FROM    dbo.Productos p
LEFT JOIN dbo.Categorias c ON c.Id = p.CategoriaId;
GO

PRINT 'Vista de compatibilidad dbo.vw_Productos creada/actualizada.';
GO
