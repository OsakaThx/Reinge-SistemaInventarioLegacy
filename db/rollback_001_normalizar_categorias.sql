-- =============================================================================
-- rollback_001_normalizar_categorias.sql
-- Laboratorio 7 - Parte D: Plan de rollback de la migracion 001
-- -----------------------------------------------------------------------------
-- Deshace los cambios de la migracion en ORDEN INVERSO:
--   vista  ->  clave foranea  ->  columna CategoriaId  ->  (tabla Categorias *)
--
-- (*) Por seguridad, la tabla Categorias NO se elimina automaticamente porque
--     forma parte del esquema base (setup_database.sql) y otros objetos pueden
--     depender de ella. La sentencia DROP TABLE queda comentada: descomentela
--     solo si esta seguro de que la tabla fue creada por esta migracion.
--
-- La columna de texto original Productos.Categoria (si existia) nunca se toca,
-- por lo que ningun dato se pierde con el rollback.
--
-- Idempotente y transaccional.
-- =============================================================================
USE InventarioLegacyDB;
GO

SET XACT_ABORT ON;
BEGIN TRAN;

-- 1) Eliminar la vista de compatibilidad
IF OBJECT_ID('dbo.vw_Productos', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Productos;

-- 2) Eliminar la clave foranea
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Productos_Categorias')
    ALTER TABLE dbo.Productos DROP CONSTRAINT FK_Productos_Categorias;

-- 3) Eliminar la columna CategoriaId
--    (Si la columna pertenece al esquema base, comente este bloque.)
IF COL_LENGTH('dbo.Productos', 'CategoriaId') IS NOT NULL
    ALTER TABLE dbo.Productos DROP COLUMN CategoriaId;

-- 4) (OPCIONAL / PELIGROSO) Eliminar la tabla Categorias.
--    Descomente solo si esta migracion creo la tabla.
-- IF OBJECT_ID('dbo.Categorias', 'U') IS NOT NULL
--     DROP TABLE dbo.Categorias;

COMMIT TRAN;
GO

PRINT 'Rollback de la migracion 001 ejecutado.';
GO
