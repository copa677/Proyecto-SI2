import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FacturasService, Factura } from '../../services_back/facturas.service';
import { ToastrService } from 'ngx-toastr';

interface FacturaCliente extends Factura {
  // Puedes extender la interfaz si necesitas propiedades adicionales en el frontend
}

@Component({
  selector: 'app-cliente-facturas',
  templateUrl: './cliente-facturas.component.html',
  styleUrls: ['./cliente-facturas.component.css']
})
export class ClienteFacturasComponent implements OnInit {
  facturas: FacturaCliente[] = [];
  cargando = false;
  idCliente: number = 0;
  
  // Filtros
  filtroEstado: string = 'todas';
  estadosFiltro = [
    { value: 'todas', label: 'Todas' },
    { value: 'pendiente', label: 'Pendientes' },
    { value: 'pagada', label: 'Pagadas' },
    { value: 'vencida', label: 'Vencidas' },
    { value: 'cancelada', label: 'Canceladas' }
  ];

  // Estadísticas
  totalPendiente = 0;
  totalPagado = 0;
  facturasPendientes = 0;

  constructor(
    private facturasService: FacturasService,
    private toastr: ToastrService,
    private router: Router
  ) {}

  ngOnInit(): void {
    const idClienteStr = localStorage.getItem('id_cliente');
    if (idClienteStr) {
      this.idCliente = parseInt(idClienteStr);
      this.cargarFacturas();
    } else {
      this.toastr.error('No se encontró información del cliente', 'Error');
      this.router.navigate(['/notes']);
    }
  }

  cargarFacturas(): void {
    this.cargando = true;
    // Usar el método específico para obtener facturas del cliente autenticado
    this.facturasService.obtenerFacturasCliente().subscribe({
      next: (facturas: FacturaCliente[]) => {
        this.facturas = facturas;
        this.calcularEstadisticas();
        this.cargando = false;
      },
      error: (error) => {
        console.error('Error al cargar facturas:', error);
        this.toastr.error('Error al cargar las facturas', 'Error');
        this.cargando = false;
      }
    });
  }

  calcularEstadisticas(): void {
    this.totalPendiente = 0;
    this.totalPagado = 0;
    this.facturasPendientes = 0;

    this.facturas.forEach(factura => {
      if (factura.estado_pago === 'pendiente') {
        this.totalPendiente += factura.monto_total;
        this.facturasPendientes++;
      } else if (factura.estado_pago === 'pagada') {
        this.totalPagado += factura.monto_total;
      }
    });
  }

  get facturasFiltradas(): FacturaCliente[] {
    if (this.filtroEstado === 'todas') {
      return this.facturas;
    }
    return this.facturas.filter(f => f.estado_pago === this.filtroEstado);
  }

  pagarFactura(factura: FacturaCliente): void {
    if (factura.estado_pago === 'pagada') {
      this.toastr.info('Esta factura ya está pagada', 'Info');
      return;
    }

    if (factura.estado_pago === 'cancelada') {
      this.toastr.error('No se puede pagar una factura cancelada', 'Error');
      return;
    }

    this.cargando = true;
    this.facturasService.crearSesionPago(factura.id_pedido).subscribe({
      next: (response) => {
        this.toastr.success('Redirigiendo a la pasarela de pago...', 'Éxito');
        window.location.href = response.checkout_url;
      },
      error: (error) => {
        console.error('Error al crear sesión de pago:', error);
        this.toastr.error(error.error?.error || 'Error al procesar el pago', 'Error');
        this.cargando = false;
      }
    });
  }

  descargarFactura(factura: FacturaCliente): void {
    this.toastr.info('Descargando factura...', 'Info');
    // Implementar descarga de PDF cuando esté disponible en el backend
    // this.facturasService.descargarPDF(factura.id_factura).subscribe({...});
  }

  verDetallePedido(factura: FacturaCliente): void {
    this.router.navigate(['/cliente/pedidos', factura.id_pedido]);
  }

  volverDashboard(): void {
    this.router.navigate(['/cliente/dashboard']);
  }

  irATienda(): void {
    this.router.navigate(['/cliente/tienda']);
  }

  irADashboard(): void {
    this.router.navigate(['/cliente/dashboard']);
  }

  irACarrito(): void {
    this.router.navigate(['/cliente/tienda']); // El carrito está en la tienda
  }

  getEstadoClase(estado: string): string {
    const clases: any = {
      'pendiente': 'bg-yellow-100 text-yellow-800',
      'pagada': 'bg-green-100 text-green-800',
      'vencida': 'bg-red-100 text-red-800',
      'cancelada': 'bg-gray-100 text-gray-800'
    };
    return clases[estado] || 'bg-gray-100 text-gray-800';
  }

  getEstadoTexto(estado: string): string {
    const textos: any = {
      'pendiente': 'Pendiente',
      'pagada': 'Pagada',
      'vencida': 'Vencida',
      'cancelada': 'Cancelada'
    };
    return textos[estado] || estado;
  }

  getMetodoPagoTexto(metodo: string | undefined): string {
    if (!metodo) return 'N/A';
    const textos: any = {
      'stripe': 'Tarjeta (Stripe)',
      'transferencia': 'Transferencia',
      'efectivo': 'Efectivo'
    };
    return textos[metodo] || metodo;
  }

  estaVencida(factura: FacturaCliente): boolean {
    if (factura.estado_pago === 'pagada' || factura.estado_pago === 'cancelada') {
      return false;
    }
    if (!factura.fecha_vencimiento) {
      return false;
    }
    const hoy = new Date();
    const fechaVencimiento = new Date(factura.fecha_vencimiento);
    
    // Validar que la fecha sea válida
    if (isNaN(fechaVencimiento.getTime())) {
      return false;
    }
    
    return fechaVencimiento < hoy;
  }

  diasParaVencer(factura: FacturaCliente): number {
    if (!factura.fecha_vencimiento) {
      return 0;
    }
    const hoy = new Date();
    const fechaVencimiento = new Date(factura.fecha_vencimiento);
    
    // Validar que la fecha sea válida
    if (isNaN(fechaVencimiento.getTime())) {
      return 0;
    }
    
    const diferencia = fechaVencimiento.getTime() - hoy.getTime();
    return Math.ceil(diferencia / (1000 * 3600 * 24));
  }
}
