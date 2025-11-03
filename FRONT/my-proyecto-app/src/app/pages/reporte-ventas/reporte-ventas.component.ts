import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ExportService } from '../../services_back/export.service';

export interface VentaReporte {
  id_venta: number;
  fecha_venta: string;
  cliente: string;
  producto: string;
  lote_asociado: string;
  cantidad: number;
  precio_total: number;
}

@Component({
  selector: 'app-reporte-ventas',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './reporte-ventas.component.html',
  styleUrls: ['./reporte-ventas.component.css']
})
export class ReporteVentasComponent implements OnInit {
  filtroForm: FormGroup;
  isLoading = true;
  reporteVentas: VentaReporte[] = [];

  constructor(
    private fb: FormBuilder,
    private exportService: ExportService
  ) {
    this.filtroForm = this.fb.group({
      lote: [''],
      cliente: ['']
    });
  }

  ngOnInit(): void {
    this.generarReporte();
  }

  generarReporte(): void {
    this.isLoading = true;
    // Simulación de llamada a la API
    setTimeout(() => {
      this.reporteVentas = this.getMockVentas();
      this.isLoading = false;
    }, 1000);
  }

  limpiarFiltros(): void {
    this.filtroForm.reset({ lote: '', cliente: '' });
    this.generarReporte();
  }

  private getMockVentas(): VentaReporte[] {
    const { lote, cliente } = this.filtroForm.value;
    let mockData = [
      { id_venta: 101, fecha_venta: '2025-10-28', cliente: 'Tienda ABC', producto: 'Camisa Clásica Blanca - Talla M', lote_asociado: 'LOTE-2025-10-A', cantidad: 50, precio_total: 1250.00 },
      { id_venta: 102, fecha_venta: '2025-10-28', cliente: 'Retail Corp', producto: 'Polera Cuello Redondo Negra - Talla L', lote_asociado: 'LOTE-2025-10-B', cantidad: 100, precio_total: 1500.00 },
      { id_venta: 103, fecha_venta: '2025-10-29', cliente: 'Tienda ABC', producto: 'Camisa de Lino Azul - Talla S', lote_asociado: 'LOTE-2025-09-C', cantidad: 25, precio_total: 750.50 },
      { id_venta: 104, fecha_venta: '2025-10-30', cliente: 'Moda Express', producto: 'Camisa Clásica Blanca - Talla M', lote_asociado: 'LOTE-2025-10-A', cantidad: 20, precio_total: 500.00 },
      { id_venta: 105, fecha_venta: '2025-10-30', cliente: 'Retail Corp', producto: 'Polera Estampada Gris - Talla M', lote_asociado: 'LOTE-2025-10-D', cantidad: 75, precio_total: 1125.00 },
    ];

    if (lote) {
      mockData = mockData.filter(v => v.lote_asociado.toLowerCase().includes(lote.toLowerCase()));
    }
    if (cliente) {
      mockData = mockData.filter(v => v.cliente.toLowerCase().includes(cliente.toLowerCase()));
    }
    return mockData;
  }

  /**
   * Calcula el total de ventas
   */
  getTotalVentas(): number {
    return this.reporteVentas.reduce((sum, venta) => sum + venta.precio_total, 0);
  }

  /**
   * Calcula la cantidad total vendida
   */
  getCantidadTotal(): number {
    return this.reporteVentas.reduce((sum, venta) => sum + venta.cantidad, 0);
  }

  /**
   * Exporta el reporte de ventas a formato Excel
   */
  exportarExcel(): void {
    if (this.reporteVentas.length === 0) {
      alert('No hay datos para exportar');
      return;
    }

    const sheets = [
      {
        sheetName: 'Ventas',
        title: 'REPORTE DE VENTAS',
        data: {
          headers: ['ID Venta', 'Fecha', 'Cliente', 'Producto', 'Lote Asociado', 'Cantidad', 'Precio Total'],
          rows: this.reporteVentas.map(item => [
            item.id_venta.toString(),
            item.fecha_venta,
            item.cliente,
            item.producto,
            item.lote_asociado,
            item.cantidad,
            item.precio_total
          ])
        }
      },
      {
        sheetName: 'Resumen',
        title: 'RESUMEN DE VENTAS',
        data: {
          headers: ['Descripción', 'Valor'],
          rows: [
            ['Total de Ventas', this.reporteVentas.length],
            ['Cantidad Total Vendida', this.getCantidadTotal()],
            ['Monto Total', this.getTotalVentas()]
          ]
        }
      }
    ];

    const infoData = [
      ['REPORTE DE VENTAS'],
      ['ManufacturaPRO'],
      [''],
      ['Fecha de Generación:', new Date().toLocaleString('es-ES')],
      [''],
    ];

    const filtros = this.filtroForm.value;
    if (filtros.lote) infoData.push(['Lote:', filtros.lote]);
    if (filtros.cliente) infoData.push(['Cliente:', filtros.cliente]);

    this.exportService.exportToExcel(
      sheets,
      `Reporte_Ventas_${new Date().toISOString().split('T')[0]}`,
      infoData
    );
  }

  /**
   * Exporta el reporte de ventas a formato PDF con gráficos
   */
  async exportarPDF(): Promise<void> {
    if (this.reporteVentas.length === 0) {
      alert('No hay datos para exportar');
      return;
    }

    const additionalInfo: string[] = [];
    const filtros = this.filtroForm.value;
    if (filtros.lote || filtros.cliente) {
      additionalInfo.push('Filtros aplicados:');
      if (filtros.lote) additionalInfo.push(`Lote: ${filtros.lote}`);
      if (filtros.cliente) additionalInfo.push(`Cliente: ${filtros.cliente}`);
    }

    // Resumen estadístico
    additionalInfo.push('');
    additionalInfo.push(`Total de ventas: ${this.reporteVentas.length}`);
    additionalInfo.push(`Cantidad total vendida: ${this.getCantidadTotal()}`);
    additionalInfo.push(`Monto total: $${this.getTotalVentas().toFixed(2)}`);

    // Agrupar ventas por cliente para el gráfico
    const ventasPorCliente = this.reporteVentas.reduce((acc, venta) => {
      if (!acc[venta.cliente]) {
        acc[venta.cliente] = 0;
      }
      acc[venta.cliente] += venta.precio_total;
      return acc;
    }, {} as { [key: string]: number });

    const sections = [
      {
        title: 'Detalle de Ventas',
        table: {
          headers: ['ID', 'Fecha', 'Cliente', 'Producto', 'Lote', 'Cantidad', 'Total'],
          rows: this.reporteVentas.map(item => [
            item.id_venta.toString(),
            item.fecha_venta,
            item.cliente,
            item.producto,
            item.lote_asociado,
            item.cantidad.toString(),
            '$' + item.precio_total.toFixed(2)
          ])
        }
      },
      {
        title: 'Ventas por Cliente',
        table: {
          headers: ['Cliente', 'Monto Total'],
          rows: Object.entries(ventasPorCliente).map(([cliente, monto]) => [
            cliente,
            '$' + monto.toFixed(2)
          ])
        },
        chartData: {
          labels: Object.keys(ventasPorCliente),
          values: Object.values(ventasPorCliente),
          label: 'Monto Total de Ventas',
          color: 'rgba(37, 99, 235, 0.6)'
        }
      }
    ];

    await this.exportService.exportToPDF(
      'REPORTE DE VENTAS',
      'ManufacturaPRO',
      sections,
      `Reporte_Ventas_${new Date().toISOString().split('T')[0]}`,
      additionalInfo
    );
  }
}