import { Injectable } from '@angular/core';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';
import { Chart, ChartConfiguration, registerables } from 'chart.js';

Chart.register(...registerables);

export interface ExportTableData {
  headers: string[];
  rows: any[][];
}

export interface ExportSheetData {
  sheetName: string;
  title?: string;
  data: ExportTableData;
}

@Injectable({
  providedIn: 'root'
})
export class ExportService {

  constructor() { }

  /**
   * Exporta datos a Excel con múltiples hojas
   */
  exportToExcel(
    sheets: ExportSheetData[],
    fileName: string,
    infoData?: string[][]
  ): void {
    const workbook = XLSX.utils.book_new();

    // Si hay información general, crear hoja de información
    if (infoData) {
      const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
      XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');
    }

    // Crear hojas para cada conjunto de datos
    sheets.forEach(sheet => {
      const sheetData: any[][] = [];
      
      // Agregar título si existe
      if (sheet.title) {
        sheetData.push([sheet.title]);
        sheetData.push([]);
      }
      
      // Agregar headers
      sheetData.push(sheet.data.headers);
      
      // Agregar filas
      sheet.data.rows.forEach(row => {
        sheetData.push(row);
      });

      const ws = XLSX.utils.aoa_to_sheet(sheetData);
      XLSX.utils.book_append_sheet(workbook, ws, sheet.sheetName);
    });

    // Generar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { 
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
    });
    saveAs(blob, `${fileName}.xlsx`);
  }

  /**
   * Exporta datos a PDF con tablas y gráficos
   */
  async exportToPDF(
    title: string,
    subtitle: string,
    sections: {
      title: string;
      table: ExportTableData;
      chartData?: { labels: string[]; values: number[]; label: string; color?: string };
    }[],
    fileName: string,
    additionalInfo?: string[]
  ): Promise<void> {
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    let yPosition = 20;

    // Encabezado principal
    doc.setFontSize(18);
    doc.setTextColor(31, 41, 55);
    doc.text(title, pageWidth / 2, yPosition, { align: 'center' });
    
    yPosition += 8;
    doc.setFontSize(12);
    doc.setTextColor(107, 114, 128);
    doc.text(subtitle, pageWidth / 2, yPosition, { align: 'center' });
    
    yPosition += 10;
    doc.setFontSize(10);
    doc.text(`Generado: ${new Date().toLocaleString('es-ES')}`, pageWidth / 2, yPosition, { align: 'center' });
    
    // Información adicional
    if (additionalInfo && additionalInfo.length > 0) {
      yPosition += 8;
      additionalInfo.forEach(info => {
        doc.text(info, pageWidth / 2, yPosition, { align: 'center' });
        yPosition += 5;
      });
    }
    
    yPosition += 10;

    // Iterar sobre cada sección
    for (let i = 0; i < sections.length; i++) {
      const section = sections[i];

      // Verificar si necesitamos nueva página
      if (yPosition > pageHeight - 50 && i > 0) {
        doc.addPage();
        yPosition = 20;
      }

      // Título de la sección
      doc.setFontSize(14);
      doc.setTextColor(79, 70, 229);
      doc.text(section.title, 14, yPosition);
      yPosition += 8;

      // Tabla
      autoTable(doc, {
        startY: yPosition,
        head: [section.table.headers],
        body: section.table.rows,
        theme: 'grid',
        headStyles: { fillColor: [79, 70, 229], textColor: 255 },
        styles: { fontSize: 9 },
      });

      yPosition = (doc as any).lastAutoTable.finalY + 15;

      // Gráfico si existe
      if (section.chartData) {
        if (yPosition > pageHeight - 90) {
          doc.addPage();
          yPosition = 20;
        }

        const chartImage = await this.generateChartImage(
          section.chartData.labels,
          section.chartData.values,
          section.title,
          section.chartData.label,
          section.chartData.color
        );

        if (chartImage) {
          doc.addImage(chartImage, 'PNG', 14, yPosition, 180, 80);
          yPosition += 90;
        }
      }

      // Agregar nueva página si no es la última sección
      if (i < sections.length - 1) {
        doc.addPage();
        yPosition = 20;
      }
    }

    // Guardar PDF
    doc.save(`${fileName}.pdf`);
  }

  /**
   * Genera una imagen de gráfico de barras
   */
  private async generateChartImage(
    labels: string[],
    data: number[],
    title: string,
    datasetLabel: string,
    backgroundColor?: string
  ): Promise<string | null> {
    const canvas = document.createElement('canvas');
    canvas.width = 800;
    canvas.height = 400;
    const ctx = canvas.getContext('2d');
    
    if (!ctx) return null;

    const config: ChartConfiguration = {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: datasetLabel,
          data: data,
          backgroundColor: backgroundColor || 'rgba(79, 70, 229, 0.6)',
          borderColor: backgroundColor?.replace('0.6', '1') || 'rgba(79, 70, 229, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: false,
        plugins: {
          title: {
            display: true,
            text: title,
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
   * Genera un gráfico de líneas (para reportes de tendencias)
   */
  async generateLineChart(
    labels: string[],
    datasets: { label: string; data: number[]; color?: string }[],
    title: string
  ): Promise<string | null> {
    const canvas = document.createElement('canvas');
    canvas.width = 800;
    canvas.height = 400;
    const ctx = canvas.getContext('2d');
    
    if (!ctx) return null;

    const colors = [
      'rgba(79, 70, 229, 0.6)',
      'rgba(37, 99, 235, 0.6)',
      'rgba(16, 185, 129, 0.6)',
      'rgba(245, 158, 11, 0.6)',
    ];

    const config: ChartConfiguration = {
      type: 'line',
      data: {
        labels: labels,
        datasets: datasets.map((dataset, index) => ({
          label: dataset.label,
          data: dataset.data,
          borderColor: dataset.color || colors[index % colors.length].replace('0.6', '1'),
          backgroundColor: dataset.color || colors[index % colors.length],
          tension: 0.3
        }))
      },
      options: {
        responsive: false,
        plugins: {
          title: {
            display: true,
            text: title,
            font: { size: 16 }
          }
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
