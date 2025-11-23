import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ExportService } from '../../services_back/export.service';
import { ReportesService, VentaReporte as VentaReporteAPI } from '../../services_back/reportes.service';

export interface VentaReporte {
  id_salida: number;
  fecha_salida: string;
  responsable: string;
  producto: string;
  lote_asociado: string;
  cantidad: number;
  precio_total: number;
  motivo?: string;
  estado?: string;
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
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private exportService: ExportService,
    private reportesService: ReportesService
  ) {
    this.filtroForm = this.fb.group({
      fechaInicio: [''],
      fechaFin: ['']
    });
  }

  ngOnInit(): void {
    this.generarReporte();
  }

  generarReporte(): void {
    this.isLoading = true;
    this.errorMessage = '';
    const { fechaInicio, fechaFin } = this.filtroForm.value;

    // Conectado al BACKEND REAL
    this.reportesService.getReporteVentas(
      fechaInicio || undefined,
      fechaFin || undefined
    ).subscribe({
      next: (data) => {
        this.reporteVentas = data.ventas;
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMessage = 'Error al cargar el reporte de ventas.';
        this.isLoading = false;
        console.error(err);
      }
    });
  }

  limpiarFiltros(): void {
    this.filtroForm.reset({ fechaInicio: '', fechaFin: '' });
    this.generarReporte();
  }

  private getMockVentas(): VentaReporte[] {
    // Datos de ejemplo - ya no se usan, se reemplazan por el backend
    let mockData: VentaReporte[] = [];

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
        title: 'REPORTE DE VENTAS (NOTAS DE SALIDA)',
        data: {
          headers: ['ID Salida', 'Fecha', 'Responsable', 'Producto', 'Lote Asociado', 'Cantidad', 'Estado'],
          rows: this.reporteVentas.map(item => [
            item.id_salida.toString(),
            item.fecha_salida,
            item.responsable,
            item.producto,
            item.lote_asociado,
            item.cantidad,
            item.estado || ''
          ])
        }
      },
      {
        sheetName: 'Resumen',
        title: 'RESUMEN DE SALIDAS',
        data: {
          headers: ['Descripción', 'Valor'],
          rows: [
            ['Total de Salidas', this.reporteVentas.length],
            ['Cantidad Total', this.getCantidadTotal()]
          ]
        }
      }
    ];

    const infoData = [
      ['REPORTE DE SALIDAS'],
      ['ManufacturaPRO'],
      [''],
      ['Fecha de Generación:', new Date().toLocaleString('es-ES')],
      [''],
    ];

    const filtros = this.filtroForm.value;
    if (filtros.fechaInicio) infoData.push(['Fecha Inicio:', filtros.fechaInicio]);
    if (filtros.fechaFin) infoData.push(['Fecha Fin:', filtros.fechaFin]);

    this.exportService.exportToExcel(
      sheets,
      `Reporte_Salidas_${new Date().toISOString().split('T')[0]}`,
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
    if (filtros.fechaInicio || filtros.fechaFin) {
      additionalInfo.push('Filtros aplicados:');
      if (filtros.fechaInicio) additionalInfo.push(`Fecha Inicio: ${filtros.fechaInicio}`);
      if (filtros.fechaFin) additionalInfo.push(`Fecha Fin: ${filtros.fechaFin}`);
    }

    // Resumen estadístico
    additionalInfo.push('');
    additionalInfo.push(`Total de salidas: ${this.reporteVentas.length}`);
    additionalInfo.push(`Cantidad total: ${this.getCantidadTotal()}`);

    // Agrupar por responsable para el gráfico
    const salidasPorResponsable = this.reporteVentas.reduce((acc, venta) => {
      if (!acc[venta.responsable]) {
        acc[venta.responsable] = 0;
      }
      acc[venta.responsable] += venta.cantidad;
      return acc;
    }, {} as { [key: string]: number });

    const sections = [
      {
        title: 'Detalle de Salidas',
        table: {
          headers: ['ID', 'Fecha', 'Responsable', 'Producto', 'Lote', 'Cantidad', 'Estado'],
          rows: this.reporteVentas.map(item => [
            item.id_salida.toString(),
            item.fecha_salida,
            item.responsable,
            item.producto,
            item.lote_asociado,
            item.cantidad.toString(),
            item.estado || ''
          ])
        }
      },
      {
        title: 'Salidas por Responsable',
        table: {
          headers: ['Responsable', 'Cantidad Total'],
          rows: Object.entries(salidasPorResponsable).map(([responsable, cantidad]) => [
            responsable,
            cantidad.toString()
          ])
        },
        chartData: {
          labels: Object.keys(salidasPorResponsable),
          values: Object.values(salidasPorResponsable),
          label: 'Cantidad Total de Salidas',
          color: 'rgba(37, 99, 235, 0.6)'
        }
      }
    ];

    await this.exportService.exportToPDF(
      'REPORTE DE SALIDAS',
      'ManufacturaPRO',
      sections,
      `Reporte_Salidas_${new Date().toISOString().split('T')[0]}`,
      additionalInfo
    );
  }
}