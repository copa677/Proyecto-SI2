import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { ReportesService, ReporteInventarioConsumo } from '../../services_back/reportes.service';
import { CommonModule } from '@angular/common';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';
import { Chart, ChartConfiguration, registerables } from 'chart.js';

@Component({
  selector: 'app-reporte-inventario',
  templateUrl: './reporte-inventario.component.html',
  styleUrls: ['./reporte-inventario.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule]
})
export class ReporteInventarioComponent implements OnInit {
  reporteData: ReporteInventarioConsumo | null = null;
  isLoading = true;
  errorMessage = '';
  filtroForm: FormGroup;

  constructor(
    private reportesService: ReportesService,
    private fb: FormBuilder
  ) {
    this.filtroForm = this.fb.group({
      fechaInicio: [''],
      fechaFin: ['']
    });
    // Registrar Chart.js
    Chart.register(...registerables);
  }

  ngOnInit(): void {
    this.generarReporte();
  }

  generarReporte(): void {
    this.isLoading = true;
    this.errorMessage = '';
    const { fechaInicio, fechaFin } = this.filtroForm.value;

    // Simulación de carga con datos de prueba (mockup)
    setTimeout(() => {
      this.reporteData = this.getMockData(fechaInicio, fechaFin);
      this.isLoading = false;
    }, 1000); // Simula 1 segundo de carga

    /*
    // CÓDIGO ORIGINAL CONECTADO AL BACKEND (descomentar para volver a conectar)
    this.reportesService.getReporteInventarioConsumo(
      fechaInicio || undefined,
      fechaFin || undefined
    ).subscribe({
      next: (data) => {
        this.reporteData = data;
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMessage = 'Error al cargar el reporte. Verifique sus permisos o la conexión con el servidor.';
        this.isLoading = false;
        console.error(err);
      }
    });*/
  }

  limpiarFiltros(): void {
    this.filtroForm.reset({ fechaInicio: '', fechaFin: '' });
    this.generarReporte();
  }

  /**
   * Genera datos de prueba para el reporte.
   */
  private getMockData(fechaInicio?: string, fechaFin?: string): ReporteInventarioConsumo {
    return {
      fecha_generacion: new Date().toISOString(),
      stock_materias_primas: [
        { nombre_materia_prima: 'Tela Algodón Pima', stock_total: 150.75, unidad_medida: 'metros' },
        { nombre_materia_prima: 'Botones de Nácar', stock_total: 2500, unidad_medida: 'unidades' },
        { nombre_materia_prima: 'Hilo de Poliéster', stock_total: 85.50, unidad_medida: 'bobinas' },
        { nombre_materia_prima: 'Etiquetas de Marca', stock_total: 5000, unidad_medida: 'unidades' },
      ],
      stock_productos_terminados: [
        { producto: 'Camisa Clásica Blanca - Talla M', cantidad: 120 },
        { producto: 'Polera Cuello Redondo Negra - Talla L', cantidad: 250 },
        { producto: 'Camisa de Lino Azul - Talla S', cantidad: 75 },
      ],
      consumo_materiales: {
        filtros: {
          fecha_inicio: fechaInicio || null,
          fecha_fin: fechaFin || null,
        },
        data: [
          { nombre_materia: 'Tela Algodón Pima', consumo_total: 45.20, unidad_medida: 'metros' },
          { nombre_materia: 'Botones de Nácar', consumo_total: 800, unidad_medida: 'unidades' },
          { nombre_materia: 'Hilo de Poliéster', consumo_total: 12.00, unidad_medida: 'bobinas' },
        ],
      },
    };
  }

  /**
   * Exporta el reporte a formato Excel con formato profesional
   */
  exportarExcel(): void {
    if (!this.reporteData) {
      alert('No hay datos para exportar');
      return;
    }

    const workbook = XLSX.utils.book_new();

    // Hoja 1: Información General
    const infoData = [
      ['REPORTE DE INVENTARIO Y CONSUMO'],
      ['ManufacturaPRO'],
      [''],
      ['Fecha de Generación:', new Date(this.reporteData.fecha_generacion).toLocaleString('es-ES')],
      [''],
    ];

    if (this.reporteData.consumo_materiales.filtros.fecha_inicio) {
      infoData.push(['Período de Consumo:', 
        `${this.reporteData.consumo_materiales.filtros.fecha_inicio} - ${this.reporteData.consumo_materiales.filtros.fecha_fin || 'Actual'}`
      ]);
    }

    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja 2: Stock de Materias Primas
    const materiasData = [
      ['STOCK DE MATERIAS PRIMAS'],
      [''],
      ['Materia Prima', 'Stock Total', 'Unidad de Medida'],
      ...this.reporteData.stock_materias_primas.map(item => [
        item.nombre_materia_prima,
        item.stock_total,
        item.unidad_medida
      ])
    ];
    const wsMaterias = XLSX.utils.aoa_to_sheet(materiasData);
    XLSX.utils.book_append_sheet(workbook, wsMaterias, 'Materias Primas');

    // Hoja 3: Stock de Productos Terminados
    const productosData = [
      ['STOCK DE PRODUCTOS TERMINADOS'],
      [''],
      ['Producto', 'Cantidad Disponible'],
      ...this.reporteData.stock_productos_terminados.map(item => [
        item.producto,
        item.cantidad
      ])
    ];
    const wsProductos = XLSX.utils.aoa_to_sheet(productosData);
    XLSX.utils.book_append_sheet(workbook, wsProductos, 'Productos Terminados');

    // Hoja 4: Consumo de Materiales
    const consumoData = [
      ['CONSUMO DE MATERIALES'],
      [''],
      ['Materia Prima', 'Consumo Total', 'Unidad de Medida'],
      ...this.reporteData.consumo_materiales.data.map(item => [
        item.nombre_materia,
        item.consumo_total,
        item.unidad_medida
      ])
    ];
    const wsConsumo = XLSX.utils.aoa_to_sheet(consumoData);
    XLSX.utils.book_append_sheet(workbook, wsConsumo, 'Consumo Materiales');

    // Generar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Inventario_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
  }

  /**
   * Exporta el reporte a formato PDF con gráficos
   */
  async exportarPDF(): Promise<void> {
    if (!this.reporteData) {
      alert('No hay datos para exportar');
      return;
    }

    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    let yPosition = 20;

    // Encabezado
    doc.setFontSize(18);
    doc.setTextColor(31, 41, 55);
    doc.text('Reporte de Inventario y Consumo', pageWidth / 2, yPosition, { align: 'center' });
    
    yPosition += 8;
    doc.setFontSize(12);
    doc.setTextColor(107, 114, 128);
    doc.text('ManufacturaPRO', pageWidth / 2, yPosition, { align: 'center' });
    
    yPosition += 10;
    doc.setFontSize(10);
    doc.text(`Generado: ${new Date(this.reporteData.fecha_generacion).toLocaleString('es-ES')}`, pageWidth / 2, yPosition, { align: 'center' });
    
    yPosition += 15;

    // Tabla 1: Stock de Materias Primas
    doc.setFontSize(14);
    doc.setTextColor(79, 70, 229);
    doc.text('Stock de Materias Primas', 14, yPosition);
    yPosition += 8;

    autoTable(doc, {
      startY: yPosition,
      head: [['Materia Prima', 'Stock Total', 'Unidad']],
      body: this.reporteData.stock_materias_primas.map(item => [
        item.nombre_materia_prima,
        item.stock_total.toFixed(2),
        item.unidad_medida
      ]),
      theme: 'grid',
      headStyles: { fillColor: [79, 70, 229], textColor: 255 },
      styles: { fontSize: 9 },
    });

    yPosition = (doc as any).lastAutoTable.finalY + 15;

    // Verificar si necesitamos una nueva página
    if (yPosition > pageHeight - 80) {
      doc.addPage();
      yPosition = 20;
    }

    // Gráfico de Stock de Materias Primas
    const chartImageMP = await this.generarGraficoMateriasPrimas();
    if (chartImageMP) {
      doc.addImage(chartImageMP, 'PNG', 14, yPosition, 180, 80);
      yPosition += 90;
    }

    // Nueva página para productos terminados
    doc.addPage();
    yPosition = 20;

    // Tabla 2: Stock de Productos Terminados
    doc.setFontSize(14);
    doc.setTextColor(79, 70, 229);
    doc.text('Stock de Productos Terminados', 14, yPosition);
    yPosition += 8;

    autoTable(doc, {
      startY: yPosition,
      head: [['Producto', 'Cantidad']],
      body: this.reporteData.stock_productos_terminados.map(item => [
        item.producto,
        item.cantidad.toString()
      ]),
      theme: 'grid',
      headStyles: { fillColor: [79, 70, 229], textColor: 255 },
      styles: { fontSize: 9 },
    });

    yPosition = (doc as any).lastAutoTable.finalY + 15;

    // Gráfico de Productos Terminados
    if (yPosition > pageHeight - 90) {
      doc.addPage();
      yPosition = 20;
    }

    const chartImagePT = await this.generarGraficoProductosTerminados();
    if (chartImagePT) {
      doc.addImage(chartImagePT, 'PNG', 14, yPosition, 180, 80);
      yPosition += 90;
    }

    // Nueva página para consumo
    doc.addPage();
    yPosition = 20;

    // Tabla 3: Consumo de Materiales
    doc.setFontSize(14);
    doc.setTextColor(79, 70, 229);
    doc.text('Consumo de Materiales', 14, yPosition);
    yPosition += 4;

    if (this.reporteData.consumo_materiales.filtros.fecha_inicio) {
      doc.setFontSize(9);
      doc.setTextColor(107, 114, 128);
      doc.text(
        `Período: ${this.reporteData.consumo_materiales.filtros.fecha_inicio} - ${this.reporteData.consumo_materiales.filtros.fecha_fin || 'Actual'}`,
        14,
        yPosition + 4
      );
      yPosition += 8;
    } else {
      yPosition += 4;
    }

    autoTable(doc, {
      startY: yPosition,
      head: [['Materia Prima', 'Consumo Total', 'Unidad']],
      body: this.reporteData.consumo_materiales.data.map(item => [
        item.nombre_materia,
        item.consumo_total.toFixed(2),
        item.unidad_medida
      ]),
      theme: 'grid',
      headStyles: { fillColor: [79, 70, 229], textColor: 255 },
      styles: { fontSize: 9 },
    });

    yPosition = (doc as any).lastAutoTable.finalY + 15;

    // Gráfico de Consumo
    if (yPosition > pageHeight - 90) {
      doc.addPage();
      yPosition = 20;
    }

    const chartImageConsumo = await this.generarGraficoConsumo();
    if (chartImageConsumo) {
      doc.addImage(chartImageConsumo, 'PNG', 14, yPosition, 180, 80);
    }

    // Guardar PDF
    const fileName = `Reporte_Inventario_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
  }

  /**
   * Genera un gráfico de barras para las materias primas
   */
  private async generarGraficoMateriasPrimas(): Promise<string | null> {
    if (!this.reporteData || this.reporteData.stock_materias_primas.length === 0) {
      return null;
    }

    const canvas = document.createElement('canvas');
    canvas.width = 800;
    canvas.height = 400;
    const ctx = canvas.getContext('2d');
    
    if (!ctx) return null;

    const config: ChartConfiguration = {
      type: 'bar',
      data: {
        labels: this.reporteData.stock_materias_primas.map(item => item.nombre_materia_prima),
        datasets: [{
          label: 'Stock Total',
          data: this.reporteData.stock_materias_primas.map(item => item.stock_total),
          backgroundColor: 'rgba(79, 70, 229, 0.6)',
          borderColor: 'rgba(79, 70, 229, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: false,
        plugins: {
          title: {
            display: true,
            text: 'Stock de Materias Primas',
            font: { size: 16 }
          },
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true }
        }
      }
    };

    const chart = new Chart(ctx, config);
    await new Promise(resolve => setTimeout(resolve, 500));
    const imageData = canvas.toDataURL('image/png');
    chart.destroy();
    
    return imageData;
  }

  /**
   * Genera un gráfico de barras para productos terminados
   */
  private async generarGraficoProductosTerminados(): Promise<string | null> {
    if (!this.reporteData || this.reporteData.stock_productos_terminados.length === 0) {
      return null;
    }

    const canvas = document.createElement('canvas');
    canvas.width = 800;
    canvas.height = 400;
    const ctx = canvas.getContext('2d');
    
    if (!ctx) return null;

    const config: ChartConfiguration = {
      type: 'bar',
      data: {
        labels: this.reporteData.stock_productos_terminados.map(item => item.producto),
        datasets: [{
          label: 'Cantidad',
          data: this.reporteData.stock_productos_terminados.map(item => item.cantidad),
          backgroundColor: 'rgba(37, 99, 235, 0.6)',
          borderColor: 'rgba(37, 99, 235, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: false,
        plugins: {
          title: {
            display: true,
            text: 'Stock de Productos Terminados',
            font: { size: 16 }
          },
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true }
        }
      }
    };

    const chart = new Chart(ctx, config);
    await new Promise(resolve => setTimeout(resolve, 500));
    const imageData = canvas.toDataURL('image/png');
    chart.destroy();
    
    return imageData;
  }

  /**
   * Genera un gráfico de barras para el consumo de materiales
   */
  private async generarGraficoConsumo(): Promise<string | null> {
    if (!this.reporteData || this.reporteData.consumo_materiales.data.length === 0) {
      return null;
    }

    const canvas = document.createElement('canvas');
    canvas.width = 800;
    canvas.height = 400;
    const ctx = canvas.getContext('2d');
    
    if (!ctx) return null;

    const config: ChartConfiguration = {
      type: 'bar',
      data: {
        labels: this.reporteData.consumo_materiales.data.map(item => item.nombre_materia),
        datasets: [{
          label: 'Consumo Total',
          data: this.reporteData.consumo_materiales.data.map(item => item.consumo_total),
          backgroundColor: 'rgba(16, 185, 129, 0.6)',
          borderColor: 'rgba(16, 185, 129, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: false,
        plugins: {
          title: {
            display: true,
            text: 'Consumo de Materiales',
            font: { size: 16 }
          },
          legend: { display: false }
        },
        scales: {
          y: { beginAtZero: true }
        }
      }
    };

    const chart = new Chart(ctx, config);
    await new Promise(resolve => setTimeout(resolve, 500));
    const imageData = canvas.toDataURL('image/png');
    chart.destroy();
    
    return imageData;
  }
}
