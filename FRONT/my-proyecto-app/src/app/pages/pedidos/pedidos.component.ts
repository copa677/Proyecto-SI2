import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PedidosService } from '../../services_back/pedidos.service';
import { Pedido } from '../../../interface/pedidos';
import { ToastrService } from 'ngx-toastr';
import { FacturasService } from '../../services_back/facturas.service';

@Component({
  selector: 'app-pedidos',
  templateUrl: './pedidos.component.html',
  styleUrls: ['./pedidos.component.css']
})
export class PedidosComponent implements OnInit {
  title = 'Gestión de Pedidos';
  subtitle = 'Administra las cotizaciones y pedidos de clientes.';

  pedidos: Pedido[] = [];
  pedidosFiltrados: Pedido[] = [];
  mostrarCancelados = false;
  filtroEstado = '';
  filtroBusqueda = '';
  cargando = false;

  // Modal de pago
  mostrarModalPago = false;
  pedidoSeleccionado: Pedido | null = null;
  metodoPagoSeleccionado: string = 'efectivo';
  procesandoPago = false;

  estadosBadgeClass: { [key: string]: string } = {
    'cotizacion': 'bg-yellow-100 text-yellow-800',
    'confirmado': 'bg-blue-100 text-blue-800',
    'en_produccion': 'bg-purple-100 text-purple-800',
    'completado': 'bg-green-100 text-green-800',
    'entregado': 'bg-green-100 text-green-800',
    'cancelado': 'bg-red-100 text-red-800'
  };

  estadosLabels: { [key: string]: string } = {
    'cotizacion': 'Cotización',
    'confirmado': 'Confirmado',
    'en_produccion': 'En Producción',
    'completado': 'Completado',
    'entregado': 'Entregado',
    'cancelado': 'Cancelado'
  };

  constructor(
    private pedidosService: PedidosService,
    private facturasService: FacturasService,
    private router: Router,
    private toastr: ToastrService
  ) {}

  ngOnInit(): void {
    this.cargarPedidos();
  }

  cargarPedidos(): void {
    this.cargando = true;
    const observable = this.mostrarCancelados 
      ? this.pedidosService.listarTodosPedidos()
      : this.pedidosService.listarPedidosActivos();

    observable.subscribe({
      next: (data) => {
        this.pedidos = data;
        this.aplicarFiltros();
        this.cargando = false;
      },
      error: (error) => {
        console.error('Error al cargar pedidos:', error);
        this.toastr.error('Error al cargar los pedidos.', 'Error');
        this.cargando = false;
      }
    });
  }

  aplicarFiltros(): void {
    const busquedaLower = this.filtroBusqueda.toLowerCase();

    this.pedidosFiltrados = this.pedidos.filter(pedido => {
      const cumpleFiltroEstado = !this.filtroEstado || pedido.estado === this.filtroEstado;
      const cumpleFiltroBusqueda = !busquedaLower || 
        pedido.cod_pedido.toLowerCase().includes(busquedaLower) ||
        (pedido.observaciones && pedido.observaciones.toLowerCase().includes(busquedaLower));
      
      return cumpleFiltroEstado && cumpleFiltroBusqueda;
    });
  }

  limpiarFiltros(): void {
    this.filtroBusqueda = '';
    this.filtroEstado = '';
    this.aplicarFiltros();
  }

  toggleMostrarCancelados(): void {
    this.mostrarCancelados = !this.mostrarCancelados;
    this.cargarPedidos();
  }

  nuevoPedido(): void {
    this.router.navigate(['/menu/pedido-form']);
  }

  verDetalle(idPedido: number): void {
    this.router.navigate(['/menu/pedido-detalle', idPedido]);
  }

  editarPedido(idPedido: number): void {
    this.router.navigate(['/menu/pedido-form', idPedido]);
  }

  cancelarPedido(pedido: Pedido): void {
    if (confirm(`¿Está seguro de cancelar el pedido ${pedido.cod_pedido}?`)) {
      this.pedidosService.eliminarPedido(pedido.id_pedido).subscribe({
        next: () => {
          this.toastr.success('Pedido cancelado correctamente.', 'Éxito');
          this.cargarPedidos();
        },
        error: (error) => {
          console.error('Error al cancelar pedido:', error);
          this.toastr.error('Error al cancelar el pedido.', 'Error');
        }
      });
    }
  }

  getEstadoBadgeClass(estado: string): string {
    return this.estadosBadgeClass[estado] || 'bg-gray-100 text-gray-800';
  }

  getEstadoLabel(estado: string): string {
    return this.estadosLabels[estado] || estado;
  }

  // ==================== MÉTODOS DE PAGO ====================

  /**
   * Abrir modal de pago para un pedido
   */
  abrirModalPago(pedido: Pedido): void {
    // Verificar que el pedido esté en estado válido para pago
    if (pedido.estado === 'cancelado') {
      this.toastr.warning('No se puede procesar el pago de un pedido cancelado.', 'Advertencia');
      return;
    }

    this.pedidoSeleccionado = pedido;
    this.metodoPagoSeleccionado = 'efectivo';
    this.mostrarModalPago = true;
  }

  /**
   * Cerrar modal de pago
   */
  cerrarModalPago(): void {
    this.mostrarModalPago = false;
    this.pedidoSeleccionado = null;
    this.metodoPagoSeleccionado = 'efectivo';
  }

  /**
   * Procesar el pago y generar factura
   */
  procesarPago(): void {
    if (!this.pedidoSeleccionado) return;

    if (!this.metodoPagoSeleccionado) {
      this.toastr.warning('Por favor, seleccione un método de pago.', 'Advertencia');
      return;
    }

    this.procesandoPago = true;

    // Si es pago con tarjeta, usar Stripe
    if (this.metodoPagoSeleccionado === 'tarjeta') {
      this.procesarPagoConStripe();
    } else {
      // Pago en efectivo - crear factura manual
      this.crearFacturaManual();
    }
  }

  /**
   * Procesar pago con Stripe (tarjeta)
   */
  procesarPagoConStripe(): void {
    if (!this.pedidoSeleccionado) return;

    this.facturasService.crearSesionPago(this.pedidoSeleccionado.id_pedido).subscribe({
      next: (response: any) => {
        if (response.checkout_url) {
          // Redirigir a Stripe para completar el pago
          this.toastr.info('Redirigiendo a la pasarela de pago...', 'Procesando');
          window.location.href = response.checkout_url;
        } else {
          this.toastr.error('No se pudo generar el link de pago.', 'Error');
          this.procesandoPago = false;
        }
      },
      error: (error: any) => {
        console.error('Error al procesar el pago con Stripe:', error);
        this.toastr.error(error.error?.error || 'Error al procesar el pago.', 'Error');
        this.procesandoPago = false;
      }
    });
  }

  /**
   * Crear factura manual (efectivo)
   */
  crearFacturaManual(): void {
    if (!this.pedidoSeleccionado) return;

    const facturaData = {
      id_pedido: this.pedidoSeleccionado.id_pedido,
      metodo_pago: this.metodoPagoSeleccionado,
      monto_total: Number(this.pedidoSeleccionado.total)
    };

    this.facturasService.crearFacturaManual(facturaData).subscribe({
      next: (response: any) => {
        this.toastr.success(`Factura ${response.cod_factura} generada correctamente.`, 'Éxito');
        this.procesandoPago = false;
        this.cerrarModalPago();
        this.cargarPedidos(); // Recargar la lista de pedidos
      },
      error: (error: any) => {
        console.error('Error al procesar el pago:', error);
        this.toastr.error(error.error?.error || 'Error al procesar el pago.', 'Error');
        this.procesandoPago = false;
      }
    });
  }

  /**
   * Verificar si un pedido ya tiene factura
   */
  pedidoTieneFactura(pedido: Pedido): boolean {
    // Asumimos que un pedido con estado 'entregado' ya tiene factura
    // O podríamos hacer una verificación adicional con el backend
    return pedido.estado === 'entregado';
  }

  /**
   * Verificar si se puede procesar el pago de un pedido
   */
  puedeProcesarPago(pedido: Pedido): boolean {
    // Se puede procesar pago si está confirmado, completado o en producción
    const estadosValidos = ['confirmado', 'completado', 'en_produccion'];
    return estadosValidos.includes(pedido.estado);
  }
}
