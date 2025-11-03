import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ExportService } from '../../services_back/export.service';

export interface ProduccionPorLote {
  lote: string;
  producto: string;
  cantidad_producida: number;
  fecha_inicio: string;
  fecha_fin: string | null;
  estado: 'En Proceso' | 'Completada' | 'Pendiente' | 'Cancelada';
}

export interface ProduccionPorEstacion {
  estacion: string;
  ordenes_activas: number;
  unidades_procesadas: number;
  eficiencia_promedio: number; // En porcentaje
}

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
  reporteProduccionLote: ProduccionPorLote[] = [];
  reporteProduccionEstacion: ProduccionPorEstacion[] = [];

  constructor(
    private fb: FormBuilder,
    private exportService: ExportService
  ) {
    this.filtroForm = this.fb.group({
      lote: [''],
      estacion: [''],
      fechaInicio: [''],
      fechaFin: ['']
    });
  }

  ngOnInit(): void {
    this.generarReporte();
  }

  generarReporte(): void {
    this.isLoading = true;
    // Simulación de llamada a la API
    setTimeout(() => {
      this.reporteProduccionLote = this.getMockProduccionLote();
      this.reporteProduccionEstacion = this.getMockProduccionEstacion();
      this.isLoading = false;
    }, 1000);
  }

  limpiarFiltros(): void {
    this.filtroForm.reset({ lote: '', estacion: '', fechaInicio: '', fechaFin: '' });
    this.generarReporte();
  }

  private getMockProduccionLote(): ProduccionPorLote[] {
    return [
      { lote: 'LOTE-2025-10-A', producto: 'Camisa Clásica Blanca - Talla M', cantidad_producida: 100, fecha_inicio: '2025-10-20', fecha_fin: '2025-10-25', estado: 'Completada' },
      { lote: 'LOTE-2025-10-B', producto: 'Polera Cuello Redondo Negra - Talla L', cantidad_producida: 250, fecha_inicio: '2025-10-22', fecha_fin: null, estado: 'En Proceso' },
      { lote: 'LOTE-2025-09-C', producto: 'Camisa de Lino Azul - Talla S', cantidad_producida: 75, fecha_inicio: '2025-09-15', fecha_fin: '2025-09-20', estado: 'Completada' },
      { lote: 'LOTE-2025-10-D', producto: 'Polera Estampada Gris - Talla M', cantidad_producida: 150, fecha_inicio: '2025-10-24', fecha_fin: null, estado: 'Pendiente' },
      { lote: 'LOTE-2025-08-A', producto: 'Camisa Manga Corta - Talla L', cantidad_producida: 80, fecha_inicio: '2025-08-01', fecha_fin: '2025-08-05', estado: 'Cancelada' },
    ];
  }

  private getMockProduccionEstacion(): ProduccionPorEstacion[] {
    return [
      { estacion: 'Corte', ordenes_activas: 2, unidades_procesadas: 850, eficiencia_promedio: 95.5 },
      { estacion: 'Costura', ordenes_activas: 5, unidades_procesadas: 720, eficiencia_promedio: 88.0 },
      { estacion: 'Estampado y Bordado', ordenes_activas: 3, unidades_procesadas: 400, eficiencia_promedio: 92.3 },
      { estacion: 'Acabado y Planchado', ordenes_activas: 4, unidades_procesadas: 650, eficiencia_promedio: 98.7 },
      { estacion: 'Empaque y Control Final', ordenes_activas: 4, unidades_procesadas: 650, eficiencia_promedio: 99.5 },
    ];
  }

  /**
   * Exporta el reporte de producción a formato Excel
   */
  exportarExcel(): void {
    if (this.reporteProduccionLote.length === 0 && this.reporteProduccionEstacion.length === 0) {
      alert('No hay datos para exportar');
      return;
    }

    const sheets = [
      {
        sheetName: 'Producción por Lote',
        title: 'PRODUCCIÓN POR LOTE',
        data: {
          headers: ['Lote', 'Producto', 'Cantidad Producida', 'Estado', 'Fecha Inicio', 'Fecha Fin'],
          rows: this.reporteProduccionLote.map(item => [
            item.lote,
            item.producto,
            item.cantidad_producida,
            item.estado,
            item.fecha_inicio,
            item.fecha_fin || 'N/A'
          ])
        }
      },
      {
        sheetName: 'Rendimiento por Estación',
        title: 'RENDIMIENTO POR ESTACIÓN DE TRABAJO',
        data: {
          headers: ['Estación', 'Órdenes Activas', 'Unidades Procesadas', 'Eficiencia Promedio (%)'],
          rows: this.reporteProduccionEstacion.map(item => [
            item.estacion,
            item.ordenes_activas,
            item.unidades_procesadas,
            item.eficiencia_promedio
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
    if (filtros.estacion) infoData.push(['Estación:', filtros.estacion]);
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
    if (this.reporteProduccionLote.length === 0 && this.reporteProduccionEstacion.length === 0) {
      alert('No hay datos para exportar');
      return;
    }

    const additionalInfo: string[] = [];
    const filtros = this.filtroForm.value;
    if (filtros.lote || filtros.estacion || filtros.fechaInicio || filtros.fechaFin) {
      additionalInfo.push('Filtros aplicados:');
      if (filtros.lote) additionalInfo.push(`Lote: ${filtros.lote}`);
      if (filtros.estacion) additionalInfo.push(`Estación: ${filtros.estacion}`);
      if (filtros.fechaInicio) additionalInfo.push(`Desde: ${filtros.fechaInicio}`);
      if (filtros.fechaFin) additionalInfo.push(`Hasta: ${filtros.fechaFin}`);
    }

    const sections = [
      {
        title: 'Producción por Lote',
        table: {
          headers: ['Lote', 'Producto', 'Cantidad', 'Estado', 'Fecha Inicio', 'Fecha Fin'],
          rows: this.reporteProduccionLote.map(item => [
            item.lote,
            item.producto,
            item.cantidad_producida.toString(),
            item.estado,
            item.fecha_inicio,
            item.fecha_fin || 'N/A'
          ])
        },
        chartData: {
          labels: this.reporteProduccionLote.map(item => item.lote),
          values: this.reporteProduccionLote.map(item => item.cantidad_producida),
          label: 'Cantidad Producida',
          color: 'rgba(79, 70, 229, 0.6)'
        }
      },
      {
        title: 'Rendimiento por Estación de Trabajo',
        table: {
          headers: ['Estación', 'Órdenes Activas', 'Unidades Procesadas', 'Eficiencia (%)'],
          rows: this.reporteProduccionEstacion.map(item => [
            item.estacion,
            item.ordenes_activas.toString(),
            item.unidades_procesadas.toString(),
            item.eficiencia_promedio.toFixed(1) + '%'
          ])
        },
        chartData: {
          labels: this.reporteProduccionEstacion.map(item => item.estacion),
          values: this.reporteProduccionEstacion.map(item => item.eficiencia_promedio),
          label: 'Eficiencia Promedio (%)',
          color: 'rgba(16, 185, 129, 0.6)'
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