# Reinge-SistemaInventarioLegacy

Sistema de inventario de consola en **C# / .NET 10** usado como **sistema base**
del curso *Reingeniería de Sistemas* (UPI). Sirve de caso de estudio para
refactoring, tests de caracterización, containerización, CI/CD y migración de
esquema.

> Para la guía completa del **Laboratorio 7** (Docker, GitHub Actions, SonarQube,
> tests y migración T-SQL) ver **[LABORATORIO7.md](LABORATORIO7.md)**.

---

## Contenido

- [Requisitos](#requisitos)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Puesta en marcha rápida](#puesta-en-marcha-rápida)
- [1. Base de datos](#1-base-de-datos)
- [2. Configuración de la conexión](#2-configuración-de-la-conexión)
- [3. Compilar y ejecutar la app](#3-compilar-y-ejecutar-la-app)
- [4. Ejecutar los tests](#4-ejecutar-los-tests)
- [5. Ejecutar con Docker](#5-ejecutar-con-docker)
- [Credenciales de prueba](#credenciales-de-prueba)
- [Solución de problemas](#solución-de-problemas)

---

## Requisitos

| Herramienta | Verificar con | Notas |
|-------------|---------------|-------|
| **.NET 10 SDK** | `dotnet --version` → `10.0.x` | requerido para compilar y probar |
| **SQL Server** | ver abajo | local, LocalDB, o el contenedor del `docker-compose.yml` |
| **Docker Desktop** *(opcional)* | `docker run hello-world` | para correr con contenedores |
| **Git** | `git --version` | — |

---

## Estructura del repositorio

```
Reinge-SistemaInventarioLegacy/
├─ Reinge-SistemaInventarioLegacy.slnx      # Solución (VS 2022+)
├─ Dockerfile                                # Imagen multi-etapa (Lab 7)
├─ docker-compose.yml                        # app + SQL Server (Lab 7)
├─ .dockerignore
├─ LABORATORIO7.md                           # Guía detallada del Lab 7
├─ .github/workflows/ci.yml                  # Pipeline CI (build + test + Sonar)
├─ db/                                        # Migración T-SQL (Lab 7)
│  ├─ migracion_001_normalizar_categorias.sql
│  ├─ rollback_001_normalizar_categorias.sql
│  └─ validacion_integridad.sql
├─ Reinge-SistemaInventarioLegacy/           # Proyecto principal (consola)
│  ├─ Program.cs                             # Menú / punto de entrada (Main)
│  ├─ AccesoDatos.cs                         # Acceso a datos (System.Data.SqlClient)
│  ├─ Modelos.cs                             # Entidades del dominio
│  ├─ Configuracion.cs                       # Cadena de conexión y parámetros
│  ├─ Reportes.cs · Utilidades.cs · refactor.cs
│  ├─ setup_database.sql                     # Crea la BD InventarioLegacyDB + datos
│  └─ Reinge-SistemaInventarioLegacy.csproj
└─ tests/
   └─ SistemaInventarioLegacy.Tests/         # Tests xUnit (caracterización)
```

---

## Puesta en marcha rápida

```bash
git clone <url-del-repo>
cd Reinge-SistemaInventarioLegacy

# (A) Preparar la base de datos (ver seccion 1)
# (B) Ajustar la cadena de conexion si hace falta (ver seccion 2)

dotnet build Reinge-SistemaInventarioLegacy.slnx        # compilar todo
dotnet test  Reinge-SistemaInventarioLegacy.slnx        # correr los tests
dotnet run --project Reinge-SistemaInventarioLegacy     # ejecutar la app
```

---

## 1. Base de datos

La aplicación usa una base **`InventarioLegacyDB`** en SQL Server. El script
[`Reinge-SistemaInventarioLegacy/setup_database.sql`](Reinge-SistemaInventarioLegacy/setup_database.sql)
la crea con todas las tablas y datos de ejemplo.

**Opción A — SQL Server local / LocalDB**

```bash
# con sqlcmd instalado
sqlcmd -S localhost -E -i Reinge-SistemaInventarioLegacy/setup_database.sql
```
O ábrelo y ejecútalo desde SQL Server Management Studio / Azure Data Studio.

**Opción B — SQL Server en Docker** (sin instalar nada)

```bash
# levanta solo el contenedor de base de datos definido en docker-compose.yml
docker compose up -d db

# aplica el esquema dentro del contenedor
docker exec -i inventario-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'Reing2026$Fuerte' -C \
  -i /dev/stdin < Reinge-SistemaInventarioLegacy/setup_database.sql
```

---

## 2. Configuración de la conexión

La cadena de conexión está en
[`Configuracion.cs`](Reinge-SistemaInventarioLegacy/Configuracion.cs):

```csharp
public static string CadenaConexion =
    "Server=localhost;Database=InventarioLegacyDB;Trusted_Connection=True;";
```

Ajústala según tu entorno. Ejemplos:

| Entorno | Cadena |
|---------|--------|
| Windows local (auth. integrada) | `Server=localhost;Database=InventarioLegacyDB;Trusted_Connection=True;` |
| SQL Server / Docker (usuario `sa`) | `Server=localhost,1433;Database=InventarioLegacyDB;User Id=sa;Password=Reing2026$Fuerte;TrustServerCertificate=True;` |

> El sistema legado lee la cadena **hardcodeada** en `Configuracion.cs`.
> Externalizarla a variables de entorno / `appsettings.json` es parte del
> ejercicio de reingeniería.

---

## 3. Compilar y ejecutar la app

```bash
dotnet build Reinge-SistemaInventarioLegacy.slnx -c Release
dotnet run --project Reinge-SistemaInventarioLegacy
```

La aplicación es de **consola interactiva**: pide inicio de sesión y muestra un
menú de inventario, clientes, pedidos y reportes.

---

## 4. Ejecutar los tests

Suite xUnit de **tests de caracterización** (golden master) sobre la lógica pura:

```bash
dotnet test Reinge-SistemaInventarioLegacy.slnx -c Release
```

Detalle de los tests y su golden master en
[LABORATORIO7.md → Parte C](LABORATORIO7.md#parte-c--tests-de-caracterización).

---

## 5. Ejecutar con Docker

```bash
docker compose up --build     # construye la app y levanta app + SQL Server
docker compose ps             # estado de los contenedores (running / healthy)
docker compose down           # detener y limpiar
```

Detalles (evidencia esperada, ejecución interactiva, SonarQube) en
[LABORATORIO7.md](LABORATORIO7.md).

---

## Credenciales de prueba

Creadas por `setup_database.sql` (contraseñas en texto plano, **intencional**
como caso de estudio de seguridad):

| Usuario | Contraseña | Rol |
|---------|-----------|-----|
| `admin` | `admin123` | Administrador |
| `operador1` | `password` | Operador |
| `supervisor1` | `12345` | Supervisor |

---

## Solución de problemas

| Síntoma | Causa / solución |
|---------|------------------|
| `A network-related or instance-specific error` al iniciar | SQL Server no accesible: revisa que el servicio/contenedor esté arriba y la cadena en `Configuracion.cs`. |
| `Cannot open database "InventarioLegacyDB"` | Falta correr `setup_database.sql` (ver sección 1). |
| `Login failed for user 'sa'` (Docker) | Password incorrecto; usa el de `docker-compose.yml` (`Reing2026$Fuerte`). |
| El contenedor `app` se cierra enseguida | Es una app de consola que espera login por stdin; usa `docker compose run app` para adjuntar terminal. |
| `dotnet` no reconocido / versión distinta | Instala el **.NET 10 SDK** (`dotnet --version` debe dar `10.0.x`). |
