// =============================================================================
// CaracterizacionTests.cs
// Laboratorio 7 - Parte C: Tests de caracterizacion (golden master)
// -----------------------------------------------------------------------------
// ALGORITMO DE FEATHERS (Working Effectively with Legacy Code):
//   1. Escribir el test.
//   2. Ejecutarlo para DESCUBRIR el valor REAL que produce el codigo actual.
//   3. CONGELAR ese valor como asercion (golden master).
//   NO se corrige el comportamiento: solo se PROTEGE contra regresiones.
//
// Estos tests cubren la logica PURA del sistema (sin base de datos):
//   * GestorVentas / ResultadoVenta / estrategias de descuento  (refactor.cs)
//   * Utilidades (calculos y lookups)                           (Utilidades.cs)
//
// Para GestorVentas.ProcesarVenta se usan dobles de prueba (fakes) como "seam"
// (Semana 4): asi se prueba el calculo sin enviar correos ni escribir archivos.
// =============================================================================

using System.Collections.Generic;
using Reinge_SistemaInventarioLegacy;   // GestorVentas, ItemVenta, PedidoVenta...
using Legacy = SistemaInventarioLegacy; // Utilidades, Configuracion...

namespace SistemaInventarioLegacy.Tests
{
    // --- Dobles de prueba (seams) para aislar la logica de la infraestructura --
    internal sealed class NotificacionFake : IServicioNotificacion
    {
        public int Llamadas { get; private set; }
        public void EnviarConfirmacion(string clienteNombre, string clienteEmail, ResultadoVenta resultado)
            => Llamadas++;
    }

    internal sealed class FacturaFake : IGeneradorFactura
    {
        public int Llamadas { get; private set; }
        public void Generar(PedidoVenta pedido, ResultadoVenta resultado)
            => Llamadas++;
    }

    public class CaracterizacionTests
    {
        // Helper: construye un pedido base de subtotal 250 (100*2 + 50*1).
        private static PedidoVenta CrearPedidoBase(TipoCliente tipo)
        {
            var items = new List<ItemVenta>
            {
                new ItemVenta(productoId: 1, cantidad: 2, precioUnitario: 100m),
                new ItemVenta(productoId: 2, cantidad: 1, precioUnitario: 50m),
            };
            return new PedidoVenta(
                clienteNombre: "Cliente Prueba",
                clienteEmail:  "cliente@example.com",
                direccion:     new DireccionCliente("Calle 1", "San Jose", "10101"),
                tipoCliente:   tipo,
                items:         items);
        }

        // ---------------------------------------------------------------------
        // 1) GestorVentas.ProcesarVenta - cliente VIP
        //    subtotal 250, desc 15% = 37.50, base 212.50, IVA 13% = 27.625
        //    Total = 250 - 37.50 + 27.625 = 240.125  (golden master)
        // ---------------------------------------------------------------------
        [Fact]
        public void ProcesarVenta_ClienteVIP_DevuelveComportamientoActual()
        {
            var gestor = new GestorVentas(new NotificacionFake(), new FacturaFake());

            ResultadoVenta r = gestor.ProcesarVenta(CrearPedidoBase(TipoCliente.VIP));

            Assert.Equal(250m,     r.Subtotal);
            Assert.Equal(37.50m,   r.Descuento);
            Assert.Equal(27.625m,  r.Impuesto);
            Assert.Equal(999m, r.Total);   // golden master (comportamiento actual)
        }

        // ---------------------------------------------------------------------
        // 2) GestorVentas.ProcesarVenta - cliente Regular
        //    desc 5% = 12.50, IVA = 237.50*0.13 = 30.875
        //    Total = 250 - 12.50 + 30.875 = 268.375  (golden master)
        // ---------------------------------------------------------------------
        [Fact]
        public void ProcesarVenta_ClienteRegular_DevuelveComportamientoActual()
        {
            var gestor = new GestorVentas(new NotificacionFake(), new FacturaFake());

            ResultadoVenta r = gestor.ProcesarVenta(CrearPedidoBase(TipoCliente.Regular));

            Assert.Equal(12.50m,   r.Descuento);
            Assert.Equal(268.375m, r.Total);
        }

        // ---------------------------------------------------------------------
        // 3) GestorVentas.ProcesarVenta - cliente Mayorista
        //    desc 20% = 50, IVA = 200*0.13 = 26, Total = 250 - 50 + 26 = 226
        // ---------------------------------------------------------------------
        [Fact]
        public void ProcesarVenta_ClienteMayorista_DevuelveComportamientoActual()
        {
            var gestor = new GestorVentas(new NotificacionFake(), new FacturaFake());

            ResultadoVenta r = gestor.ProcesarVenta(CrearPedidoBase(TipoCliente.Mayorista));

            Assert.Equal(50m,  r.Descuento);
            Assert.Equal(226m, r.Total);
        }

        // ---------------------------------------------------------------------
        // 4) ProcesarVenta invoca a los colaboradores (factura + notificacion).
        //    Congela el comportamiento observable a traves de los seams.
        // ---------------------------------------------------------------------
        [Fact]
        public void ProcesarVenta_InvocaFacturaYNotificacionUnaVez()
        {
            var notificacion = new NotificacionFake();
            var factura      = new FacturaFake();
            var gestor       = new GestorVentas(notificacion, factura);

            gestor.ProcesarVenta(CrearPedidoBase(TipoCliente.Regular));

            Assert.Equal(1, factura.Llamadas);
            Assert.Equal(1, notificacion.Llamadas);
        }

        // ---------------------------------------------------------------------
        // 5) Estrategia de descuento Mayorista: 20% sobre 1000 = 200
        // ---------------------------------------------------------------------
        [Fact]
        public void FabricaDescuento_Mayorista_Calcula20Porciento()
        {
            ICalculadorDescuento calc = FabricaDescuento.Crear(TipoCliente.Mayorista);

            Assert.Equal(200m, calc.Calcular(1000m));
        }

        // ---------------------------------------------------------------------
        // 6) ItemVenta.Subtotal = cantidad * precioUnitario  (3 * 1500 = 4500)
        // ---------------------------------------------------------------------
        [Fact]
        public void ItemVenta_Subtotal_EsCantidadPorPrecio()
        {
            var item = new ItemVenta(productoId: 1, cantidad: 3, precioUnitario: 1500m);

            Assert.Equal(4500m, item.Subtotal);
        }

        // ---------------------------------------------------------------------
        // 7) Utilidades.CalcularImpuesto: 13% de IVA sobre 1000 = 130
        // ---------------------------------------------------------------------
        [Fact]
        public void Utilidades_CalcularImpuesto_Aplica13Porciento()
        {
            Assert.Equal(130m, Legacy.Utilidades.CalcularImpuesto(1000m));
        }

        // ---------------------------------------------------------------------
        // 8) Utilidades.CalcularDescuento - Mayorista (tipo 2) = 10% de 1000 = 100
        //    OJO: el codigo legado usa 10% para Mayorista (Configuracion), a
        //    diferencia del 20% de GestorVentas. El golden master CONGELA el
        //    comportamiento actual, no lo "corrige".
        // ---------------------------------------------------------------------
        [Fact]
        public void Utilidades_CalcularDescuento_Mayorista_Aplica10Porciento()
        {
            Assert.Equal(100m, Legacy.Utilidades.CalcularDescuento(1000m, 2));
        }

        // ---------------------------------------------------------------------
        // 9) Utilidades.CalcularMargen: ((225 - 150) / 150) * 100 = 50 (%)
        // ---------------------------------------------------------------------
        [Fact]
        public void Utilidades_CalcularMargen_DevuelvePorcentaje()
        {
            Assert.Equal(50m, Legacy.Utilidades.CalcularMargen(precioCompra: 150m, precioVenta: 225m));
        }

        // ---------------------------------------------------------------------
        // 10) Utilidades.ObtenerNombreEstadoPedido: lookup independiente de cultura
        // ---------------------------------------------------------------------
        [Theory]
        [InlineData(1, "Pendiente")]
        [InlineData(3, "Enviado")]
        [InlineData(5, "Cancelado")]
        [InlineData(99, "Desconocido")]
        public void Utilidades_ObtenerNombreEstadoPedido_MapeaCodigos(int estado, string esperado)
        {
            Assert.Equal(esperado, Legacy.Utilidades.ObtenerNombreEstadoPedido(estado));
        }
    }
}
