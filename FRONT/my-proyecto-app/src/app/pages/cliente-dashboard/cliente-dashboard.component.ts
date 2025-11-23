import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PedidosService } from '../../services_back/pedidos.service';
import { FacturasService } from '../../services_back/facturas.service';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-cliente-dashboard',
  templateUrl: './cliente-dashboard.component.html',
  styleUrls: ['./cliente-dashboard.component.css']
})
export class ClienteDashboardComponent implements OnInit {
  nombreUsuario: string = '';
  emailUsuario: string = '';
  idCliente: number = 0;
  cargando = false;

  estadisticas = {
    pedidos_activos: 0,
    pedidos_completados: 0,
    facturas_pendientes: 0,
    facturas_pagadas: 0,
    monto_total_pendiente: 0,
    monto_total_pagado: 0
  };

  pedidosRecientes: any[] = [];
  facturasProximasVencer: any[] = [];

  // Gráficos y métricas
  graficoEstadoPedidos: any = {
    cotizacion: 0,
    confirmado: 0,
    en_produccion: 0,
    completado: 0,
    entregado: 0
  };

  constructor(
    private router: Router,
    private pedidosService: PedidosService,
    private facturasService: FacturasService,
    private toastr: ToastrService
  ) {}

  ngOnInit(): void {
    // Obtener datos del usuario desde localStorage
    this.nombreUsuario = localStorage.getItem('username') || 'Cliente';
    this.emailUsuario = localStorage.getItem('email') || '';
    
    const idClienteStr = localStorage.getItem('id_cliente');
    if (idClienteStr) {
      this.idCliente = parseInt(idClienteStr);
      this.cargarEstadisticas();
      this.cargarPedidosRecientes();
      this.cargarFacturasProximasVencer();
    } else {
      this.toastr.error('No se encontró información del cliente', 'Error');
      this.router.navigate(['/notes']);
    }
  }

  cargarEstadisticas(): void {
    this.cargando = true;

    // Cargar pedidos
    this.pedidosService.listarTodosPedidos().subscribe({
      next: (pedidos) => {
        const pedidosCliente = pedidos.filter(p => p.id_cliente === this.idCliente);
        
        this.estadisticas.pedidos_activos = pedidosCliente.filter(p => 
          ['cotizacion', 'confirmado', 'en_produccion'].includes(p.estado)
        ).length;
        
        this.estadisticas.pedidos_completados = pedidosCliente.filter(p => 
          ['completado', 'entregado'].includes(p.estado)
        ).length;

        // Contar por estado para gráfico
        pedidosCliente.forEach(p => {
          if (this.graficoEstadoPedidos.hasOwnProperty(p.estado)) {
            this.graficoEstadoPedidos[p.estado]++;
          }
        });

        this.cargando = false;
      },
      error: (error) => {
        console.error('Error al cargar estadísticas de pedidos:', error);
        this.cargando = false;
      }
    });

    // Cargar facturas
    this.facturasService.obtenerFacturas().subscribe({
      next: (facturas: any[]) => {
        this.estadisticas.facturas_pendientes = facturas.filter(f => 
          f.estado_pago === 'pendiente'
        ).length;
        
        this.estadisticas.facturas_pagadas = facturas.filter(f => 
          f.estado_pago === 'pagada'
        ).length;

        this.estadisticas.monto_total_pendiente = facturas
          .filter(f => f.estado_pago === 'pendiente')
          .reduce((sum, f) => sum + f.monto_total, 0);

        this.estadisticas.monto_total_pagado = facturas
          .filter(f => f.estado_pago === 'pagada')
          .reduce((sum, f) => sum + f.monto_total, 0);
      },
      error: (error) => {
        console.error('Error al cargar estadísticas de facturas:', error);
      }
    });
  }

  cargarPedidosRecientes(): void {
    this.pedidosService.listarTodosPedidos().subscribe({
      next: (pedidos) => {
        this.pedidosRecientes = pedidos
          .filter(p => p.id_cliente === this.idCliente)
          .sort((a, b) => new Date(b.fecha_creacion).getTime() - new Date(a.fecha_creacion).getTime())
          .slice(0, 5);
      },
      error: (error) => {
        console.error('Error al cargar pedidos recientes:', error);
      }
    });
  }

  cargarFacturasProximasVencer(): void {
    this.facturasService.obtenerFacturas().subscribe({
      next: (facturas: any[]) => {
        const hoy = new Date();
        this.facturasProximasVencer = facturas
          .filter(f => {
            if (f.estado_pago !== 'pendiente') return false;
            const fechaVencimiento = new Date(f.fecha_vencimiento);
            const diasRestantes = Math.ceil((fechaVencimiento.getTime() - hoy.getTime()) / (1000 * 3600 * 24));
            return diasRestantes <= 7 && diasRestantes >= 0;
          })
          .sort((a, b) => new Date(a.fecha_vencimiento).getTime() - new Date(b.fecha_vencimiento).getTime())
          .slice(0, 5);
      },
      error: (error) => {
        console.error('Error al cargar facturas próximas a vencer:', error);
      }
    });
  }

  irAPedidos(): void {
    this.router.navigate(['/cliente/pedidos']);
  }

  irATienda(): void {
    this.router.navigate(['/cliente/tienda']);
  }

  irAFacturas(): void {
    this.router.navigate(['/cliente/facturas']);
  }

  verDetallePedido(pedido: any): void {
    this.router.navigate(['/cliente/pedidos', pedido.id_pedido]);
  }

  pagarFactura(factura: any): void {
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

  cerrarSesion(): void {
    localStorage.clear();
    this.router.navigate(['/notes']);
  }

  getEstadoClase(estado: string): string {
    const clases: any = {
      'cotizacion': 'bg-yellow-100 text-yellow-800',
      'confirmado': 'bg-blue-100 text-blue-800',
      'en_produccion': 'bg-purple-100 text-purple-800',
      'completado': 'bg-green-100 text-green-800',
      'entregado': 'bg-gray-100 text-gray-800',
      'cancelado': 'bg-red-100 text-red-800',
      'pendiente': 'bg-yellow-100 text-yellow-800',
      'pagada': 'bg-green-100 text-green-800'
    };
    return clases[estado] || 'bg-gray-100 text-gray-800';
  }

  getEstadoTexto(estado: string): string {
    const textos: any = {
      'cotizacion': 'Cotización',
      'confirmado': 'Confirmado',
      'en_produccion': 'En Producción',
      'completado': 'Completado',
      'entregado': 'Entregado',
      'cancelado': 'Cancelado',
      'pendiente': 'Pendiente',
      'pagada': 'Pagada'
    };
    return textos[estado] || estado;
  }

  diasParaVencer(factura: any): number {
    const hoy = new Date();
    const fechaVencimiento = new Date(factura.fecha_vencimiento);
    const diferencia = fechaVencimiento.getTime() - hoy.getTime();
    return Math.ceil(diferencia / (1000 * 3600 * 24));
  }

  get totalPedidos(): number {
    return this.estadisticas.pedidos_activos + this.estadisticas.pedidos_completados;
  }

  get totalFacturas(): number {
    return this.estadisticas.facturas_pendientes + this.estadisticas.facturas_pagadas;
  }

  get porcentajePedidosCompletados(): number {
    if (this.totalPedidos === 0) return 0;
    return (this.estadisticas.pedidos_completados / this.totalPedidos) * 100;
  }
}
