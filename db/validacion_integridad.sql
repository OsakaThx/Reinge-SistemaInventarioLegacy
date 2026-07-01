-- =============================================================================
-- validacion_integridad.sql
-- Laboratorio 7 - Parte D.5: Validacion de integridad
-- -----------------------------------------------------------------------------
-- Ejecute estas consultas ANTES y DESPUES de migrar y registre los resultados
-- en el informe. Los conteos deben ser consistentes (no se pierden filas).
-- =============================================================================
USE InventarioLegacyDB;
GO

-- A) Conteo total de productos (debe ser igual antes y despues de migrar)
SELECT COUNT(*) AS TotalProductos
FROM   dbo.Productos;

-- B) Productos sin categoria vinculada.
--    Si todos los productos tienen una categoria valida, deberia ser 0.
SELECT COUNT(*) AS SinVincular
FROM   dbo.Productos
WHERE  CategoriaId IS NULL;

-- C) La vista de compatibilidad debe devolver la misma cantidad de filas
--    que la tabla original.
SELECT COUNT(*) AS FilasVista
FROM   dbo.vw_Productos;

-- D) Comprobacion cruzada: cada CategoriaId apunta a una categoria existente.
--    Deberia ser 0 (la FK lo garantiza, pero se valida explicitamente).
SELECT COUNT(*) AS HuerfanosCategoria
FROM   dbo.Productos p
LEFT JOIN dbo.Categorias c ON c.Id = p.CategoriaId
WHERE  p.CategoriaId IS NOT NULL
  AND  c.Id IS NULL;
GO
