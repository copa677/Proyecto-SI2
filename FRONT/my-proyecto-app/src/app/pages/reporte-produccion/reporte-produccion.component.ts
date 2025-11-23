import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ExportService } from '../../services_back/export.service';
import { ReportesService, OrdenProduccionReporte } from '../../services_back/reportes.service';

@Component({
  selector: 'app-reporte-produccion',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './reporte-produccion.component.html',
  styleUrls: ['./reporte-produccion.component.css']
})
export class ReporteProduccionComponent implements OnInit {
  filtroForm: FormGroup;
  isLoading = true;
  reporteProduccion: OrdenProduccionReporte[] = [];
  estadisticas: any = null;
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
    this.reportesService.getReporteProduccion(
      fechaInicio || undefined,
      fechaFin || undefined
    ).subscribe({
      next: (data) => {
        this.reporteProduccion = data.ordenes;
        this.estadisticas = data.estadisticas;
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMessage = 'Error al cargar el reporte de producción.';
        this.isLoading = false;
        console.error(err);
      }
    });
  }

  limpiarFiltros(): void {
    this.filtroForm.reset({ fechaInicio: '', fechaFin: '' });
    this.generarReporte();
  }

  /**
   * Exporta el reporte de producción a formato Excel
   */
  exportarExcel(): void {
    if (this.reporteProduccion.length === 0) {
      alert('No hay datos para exportar');
      return;
    }

    const sheets = [
      {
        sheetName: 'Órdenes de Producción',
        title: 'ÓRDENES DE PRODUCCIÓN',
        data: {
          headers: ['ID Orden', 'Código', 'Producto', 'Color', 'Talla', 'Cantidad', 'Estado', 'Fecha Inicio', 'Fecha Fin', 'Responsable'],
          rows: this.reporteProduccion.map(item => [
            item.id_orden,
            item.cod_orden,
            item.producto_modelo,
            item.color,
            item.talla,
            item.cantidad_total,
            item.estado,
            item.fecha_inicio,
            item.fecha_fin || 'N/A',
            item.responsable || 'N/A'
          ])
        }
      }
    ];

    const infoData = [
      ['REPORTE DE PRODUCCIÓN'],
      ['ManufacturaPRO'],
      [''],
      ['Fecha de Generación:', new Date().toLocaleString('es-ES')],
      [''],
    ];

    const filtros = this.filtroForm.value;
    if (filtros.lote) infoData.push(['Lote:', filtros.lote]);
    if (filtros.estado) infoData.push(['Estado:', filtros.estado]);
    if (filtros.fechaInicio) infoData.push(['Fecha Inicio:', filtros.fechaInicio]);
    if (filtros.fechaFin) infoData.push(['Fecha Fin:', filtros.fechaFin]);

    this.exportService.exportToExcel(
      sheets,
      `Reporte_Produccion_${new Date().toISOString().split('T')[0]}`,
      infoData
    );
  }

  /**
   * Exporta el reporte de producción a formato PDF con gráficos
   */
  async exportarPDF(): Promise<void> {
    if (this.reporteProduccion.length === 0) {
      alert('No hay datos para exportar');
      return;
    }

    const additionalInfo: string[] = [];
    const filtros = this.filtroForm.value;
    if (filtros.lote || filtros.estado || filtros.fechaInicio || filtros.fechaFin) {
      additionalInfo.push('Filtros aplicados:');
      if (filtros.lote) additionalInfo.push(`Lote: ${filtros.lote}`);
      if (filtros.estado) additionalInfo.push(`Estado: ${filtros.estado}`);
      if (filtros.fechaInicio) additionalInfo.push(`Desde: ${filtros.fechaInicio}`);
      if (filtros.fechaFin) additionalInfo.push(`Hasta: ${filtros.fechaFin}`);
    }

    // Agrupar por estado para estadísticas
    const ordenesPorEstado = this.reporteProduccion.reduce((acc, item) => {
      acc[item.estado] = (acc[item.estado] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    const sections = [
      {
        title: 'Órdenes de Producción',
        table: {
          headers: ['ID', 'Código', 'Producto', 'Color', 'Talla', 'Cantidad', 'Estado', 'Fecha Inicio', 'Fecha Fin'],
          rows: this.reporteProduccion.map(item => [
            item.id_orden.toString(),
            item.cod_orden,
            item.producto_modelo,
            item.color,
            item.talla,
            item.cantidad_total.toString(),
            item.estado,
            item.fecha_inicio,
            item.fecha_fin || 'N/A'
          ])
        },
        chartData: {
          labels: Object.keys(ordenesPorEstado),
          values: Object.values(ordenesPorEstado),
          label: 'Órdenes por Estado',
          color: 'rgba(79, 70, 229, 0.6)'
        }
      }
    ];

    await this.exportService.exportToPDF(
      'REPORTE DE PRODUCCIÓN',
      'ManufacturaPRO',
      sections,
      `Reporte_Produccion_${new Date().toISOString().split('T')[0]}`,
      additionalInfo
    );
  }
}