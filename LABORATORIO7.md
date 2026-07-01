# Laboratorio 7 — Implementación y Migración

Entregables del Laboratorio 7 aplicados al sistema base **SistemaInventarioLegacy**.
Adaptado a **.NET 10** (el proyecto y los microservicios gRPC del curso usan .NET 10,
no .NET 8 como traía el enunciado original).

## Parte A — Containerización (25 pts)
- [`Dockerfile`](Dockerfile) — build multi-etapa (SDK 10.0 → runtime 10.0), patrón tomado de los microservicios gRPC.
- [`docker-compose.yml`](docker-compose.yml) — `app` + `db` (SQL Server 2022), la app espera el `healthcheck` de SQL Server.
- [`.dockerignore`](.dockerignore) — reduce el contexto de build.

```bash
docker compose up --build     # construir e iniciar todo
docker compose ps             # ver estado (running / healthy)
docker compose down           # detener y limpiar
```
> La app es de consola e interactiva (login por stdin). Para adjuntar terminal: `docker compose run app`.
> Imagen verificada: `docker build -t inventario-legacy:lab7 .` compila y publica correctamente.

## Parte B — CI/CD con GitHub Actions (20 pts)
- [`.github/workflows/ci.yml`](.github/workflows/ci.yml) — `restore → build → test → SonarQube`.
- El job de tests pone el pipeline en **rojo** ante cualquier regresión (demo anti-regresión).
- SonarQube corre solo si existen los secrets `SONAR_TOKEN` y `SONAR_HOST_URL` (Settings → Secrets → Actions).

## Parte C — Tests de caracterización (25 pts)
- [`tests/SistemaInventarioLegacy.Tests`](tests/SistemaInventarioLegacy.Tests) — proyecto xUnit (net10.0).
- [`CaracterizacionTests.cs`](tests/SistemaInventarioLegacy.Tests/CaracterizacionTests.cs) — **10 tests / 13 casos** (golden master) sobre `GestorVentas` y `Utilidades`.

```bash
dotnet test -c Release        # 13 casos, todos en verde
```

| # | Método probado | Entrada | Golden master |
|---|----------------|---------|---------------|
| 1 | `GestorVentas.ProcesarVenta` (VIP) | subtotal 250 | Total = 240.125 |
| 2 | `GestorVentas.ProcesarVenta` (Regular) | subtotal 250 | Total = 268.375 |
| 3 | `GestorVentas.ProcesarVenta` (Mayorista) | subtotal 250 | Total = 226 |
| 4 | `ProcesarVenta` invoca factura + notificación | pedido base | 1 llamada c/u |
| 5 | `FabricaDescuento` (Mayorista) | 1000 | 200 |
| 6 | `ItemVenta.Subtotal` | 3 × 1500 | 4500 |
| 7 | `Utilidades.CalcularImpuesto` | 1000 | 130 |
| 8 | `Utilidades.CalcularDescuento` (tipo 2) | 1000 | 100 |
| 9 | `Utilidades.CalcularMargen` | 150 / 225 | 50 |
| 10 | `Utilidades.ObtenerNombreEstadoPedido` | 1,3,5,99 | Pendiente/Enviado/Cancelado/Desconocido |

## Parte D — Migración de esquema en T-SQL (25 pts)
Carpeta [`db/`](db):
- [`migracion_001_normalizar_categorias.sql`](db/migracion_001_normalizar_categorias.sql) — migración idempotente + **vista de compatibilidad** `vw_Productos`.
- [`rollback_001_normalizar_categorias.sql`](db/rollback_001_normalizar_categorias.sql) — plan de rollback (no destructivo).
- [`validacion_integridad.sql`](db/validacion_integridad.sql) — consultas de validación antes/después.
