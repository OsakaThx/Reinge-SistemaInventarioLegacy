# =============================================================================
# Dockerfile  -  SistemaInventarioLegacy
# Laboratorio 7 - Parte A: Containerizacion (build multi-etapa)
# -----------------------------------------------------------------------------
# Se adapta el patron multi-etapa de los microservicios gRPC del curso
# (ProductService.gRPC / UserService.gRPC, etc.) al sistema legado.
#
# NOTA: el proyecto base apunta a net10.0 (ver .csproj) y los microservicios
# que ya funcionan usan las imagenes 10.0, por eso aqui se usa .NET 10 y NO
# .NET 8 como traia el enunciado original del laboratorio.
#
# Al ser una aplicacion de CONSOLA (no web) la imagen final es 'runtime'
# y no 'aspnet'.
# =============================================================================

# ----------------------------------------------------------------------------
# Etapa 1: Build  (SDK completo: restaura, compila y publica)
# ----------------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copiar solo el .csproj primero para aprovechar la cache de capas de Docker:
# si no cambian las dependencias, 'restore' no se vuelve a ejecutar.
COPY ["Reinge-SistemaInventarioLegacy/Reinge-SistemaInventarioLegacy.csproj", "Reinge-SistemaInventarioLegacy/"]
RUN dotnet restore "Reinge-SistemaInventarioLegacy/Reinge-SistemaInventarioLegacy.csproj"

# Copiar el resto del codigo fuente del proyecto principal
COPY Reinge-SistemaInventarioLegacy/ Reinge-SistemaInventarioLegacy/

WORKDIR /src/Reinge-SistemaInventarioLegacy
RUN dotnet publish "Reinge-SistemaInventarioLegacy.csproj" \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

# ----------------------------------------------------------------------------
# Etapa 2: Runtime  (imagen liviana, solo el runtime de .NET)
# ----------------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS final
WORKDIR /app

# Copiar los binarios publicados desde la etapa de build
COPY --from=build /app/publish .

# Punto de entrada: el ensamblado del sistema legado
ENTRYPOINT ["dotnet", "Reinge-SistemaInventarioLegacy.dll"]
