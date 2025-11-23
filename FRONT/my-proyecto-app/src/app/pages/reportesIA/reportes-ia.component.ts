import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { ToastrService } from 'ngx-toastr';
import { ReportesService } from '../../services_back/reportes.service';
import { ExportService } from '../../services_back/export.service';
import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { environment } from '../../../environments/environment';

interface Reporte {
  id: number;
  tipo: string;
  descripcion: string;
  fecha: Date;
  estado: 'generando' | 'completado' | 'error';
  comando: string;
  url?: string;
  datosReporte?: any;
}

declare global {
  interface Window {
    webkitSpeechRecognition: any;
    SpeechRecognition: any;
  }
}

@Component({
  selector: 'app-reportes-ia',
  templateUrl: './reportes-ia.component.html',
  styleUrls: ['./reportes-ia.component.css']
})
export class ReportesIAComponent implements OnInit {
  
  reportes: Reporte[] = [];
  escuchando = false;
  comandoActual = '';
  soportaVoz = false;
  recognition: any = null;
  
  // Filtros
  busqueda = '';
  filtroEstado: '' | 'generando' | 'completado' | 'error' = '';
  
  // Historial de comandos
  historialComandos: string[] = [];
  
  // Tipos de reportes disponibles
  tiposReportes = [
    { valor: 'ventas', label: 'Reporte de Ventas', ejemplo: 'Genera un reporte de ventas del último mes', icon: 'fa-shopping-cart', color: 'blue' },
    { valor: 'inventario', label: 'Reporte de Inventario', ejemplo: 'Muestra el reporte de inventario actual', icon: 'fa-boxes', color: 'green' },
    { valor: 'produccion', label: 'Reporte de Producción', ejemplo: 'Crea un reporte de producción de esta semana', icon: 'fa-industry', color: 'purple' },
    { valor: 'clientes', label: 'Reporte de Clientes', ejemplo: 'Dame el reporte de clientes registrados', icon: 'fa-users', color: 'yellow' },
    { valor: 'bitacora', label: 'Reporte de Bitácora', ejemplo: 'Genera un reporte de bitácora del último día', icon: 'fa-clipboard-list', color: 'red' },
    { valor: 'personal', label: 'Reporte de Personal', ejemplo: 'Muestra el reporte de personal y empleados', icon: 'fa-user-tie', color: 'indigo' },
    { valor: 'pedidos', label: 'Reporte de Pedidos', ejemplo: 'Genera un reporte de pedidos del mes', icon: 'fa-file-invoice', color: 'pink' },
  ];

  constructor(
    private toastr: ToastrService,
    private reportesService: ReportesService,
    private exportService: ExportService,
    private http: HttpClient
  ) { }

  ngOnInit(): void {
    this.verificarSoporteVoz();
    this.cargarHistorial();
  }

  verificarSoporteVoz(): void {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    this.soportaVoz = !!SpeechRecognition;
    
    if (this.soportaVoz) {
      this.recognition = new SpeechRecognition();
      this.recognition.lang = 'es-ES';
      this.recognition.interimResults = false;
      this.recognition.maxAlternatives = 1;
      this.recognition.continuous = false;
      
      this.recognition.onstart = () => {
        this.escuchando = true;
        this.comandoActual = '';
        console.log('Reconocimiento de voz iniciado...');
      };
      
      this.recognition.onresult = (event: any) => {
        const transcript = event.results[0][0].transcript;
        console.log('Comando detectado:', transcript);
        this.comandoActual = transcript;
        this.procesarComando(transcript);
      };
      
      this.recognition.onerror = (event: any) => {
        console.error('Error en reconocimiento de voz:', event.error);
        this.escuchando = false;
        
        if (event.error === 'no-speech') {
          this.toastr.warning('No se detectó ningún comando de voz', 'Atención');
        } else if (event.error === 'not-allowed') {
          this.toastr.error('Permiso de micrófono denegado. Por favor, habilítelo en la configuración del navegador.', 'Error');
        } else {
          this.toastr.error(`Error: ${event.error}`, 'Error de reconocimiento');
        }
      };
      
      this.recognition.onend = () => {
        this.escuchando = false;
        console.log('Reconocimiento de voz finalizado');
      };
    } else {
      this.toastr.warning('Tu navegador no soporta reconocimiento de voz. Intenta con Chrome o Edge.', 'Atención');
    }
  }

  iniciarComandoVoz(): void {
    if (!this.soportaVoz) {
      this.toastr.error('El reconocimiento de voz no está disponible en tu navegador', 'Error');
      return;
    }
    
    try {
      this.recognition.start();
      this.toastr.info('Escuchando... Habla ahora', 'Micrófono activado');
    } catch (error) {
      console.error('Error al iniciar reconocimiento:', error);
      this.toastr.error('No se pudo iniciar el reconocimiento de voz', 'Error');
    }
  }

  detenerComandoVoz(): void {
    if (this.recognition && this.escuchando) {
      this.recognition.stop();
    }
  }

  procesarComando(comando: string): void {
    const comandoLower = comando.toLowerCase();
    
    // Guardar en historial
    this.historialComandos.unshift(comando);
    if (this.historialComandos.length > 10) {
      this.historialComandos.pop();
    }
    this.guardarHistorial();
    
    // Detectar tipo de reporte basado en palabras clave y generar reporte real
    if (comandoLower.includes('venta')) {
      this.generarReporteVentas();
    } else if (comandoLower.includes('inventario') || comandoLower.includes('stock')) {
      this.generarReporteInventario();
    } else if (comandoLower.includes('producción') || comandoLower.includes('produccion')) {
      this.generarReporteProduccion();
    } else if (comandoLower.includes('cliente')) {
      this.generarReporteClientes();
    } else if (comandoLower.includes('bitácora') || comandoLower.includes('bitacora') || comandoLower.includes('log') || comandoLower.includes('actividad')) {
      this.generarReporteBitacora();
    } else if (comandoLower.includes('personal') || comandoLower.includes('empleado') || comandoLower.includes('trabajador')) {
      this.generarReportePersonal();
    } else if (comandoLower.includes('pedido') || comandoLower.includes('orden')) {
      this.generarReportePedidos();
    } else {
      // Comando no reconocido
      this.toastr.warning('No se pudo identificar el tipo de reporte. Palabras clave: ventas, inventario, producción, clientes, bitácora, personal, pedidos', 'Comando no reconocido');
    }
  }

  simularGeneracionReporte(id: number): void {
    const reporte = this.reportes.find(r => r.id === id);
    if (reporte) {
      reporte.estado = 'completado';
      reporte.url = `/api/reportes/download/${id}`;
      this.toastr.success('Reporte generado correctamente', 'Completado');
    }
  }

  // ========== GENERACIÓN MANUAL DE REPORTES ==========

  generarReporteInventario(): void {
    const nuevoReporte: Reporte = {
      id: Date.now(),
      tipo: 'Inventario',
      descripcion: 'Reporte de inventario y consumo de materiales',
      fecha: new Date(),
      estado: 'generando',
      comando: 'Generación manual - Reporte de Inventario'
    };
    
    this.reportes.unshift(nuevoReporte);
    this.toastr.info('Generando reporte de inventario...', 'Procesando');
    
    this.reportesService.getReporteInventarioConsumo().subscribe({
      next: (data) => {
        nuevoReporte.estado = 'completado';
        nuevoReporte.datosReporte = data;
        this.toastr.success('Reporte de inventario generado', 'Completado');
      },
      error: (err) => {
        nuevoReporte.estado = 'error';
        nuevoReporte.descripcion += ' (Error al generar)';
        this.toastr.error('Error al generar reporte de inventario', 'Error');
        console.error(err);
      }
    });
  }

  generarReporteVentas(): void {
    const nuevoReporte: Reporte = {
      id: Date.now(),
      tipo: 'Ventas',
      descripcion: 'Reporte de ventas y salidas de productos',
      fecha: new Date(),
      estado: 'generando',
      comando: 'Generación manual - Reporte de Ventas'
    };
    
    this.reportes.unshift(nuevoReporte);
    this.toastr.info('Generando reporte de ventas...', 'Procesando');
    
    this.reportesService.getReporteVentas().subscribe({
      next: (data) => {
        nuevoReporte.estado = 'completado';
        nuevoReporte.datosReporte = data;
        this.toastr.success('Reporte de ventas generado', 'Completado');
      },
      error: (err) => {
        nuevoReporte.estado = 'error';
        nuevoReporte.descripcion += ' (Error al generar)';
        this.toastr.error('Error al generar reporte de ventas', 'Error');
        console.error(err);
      }
    });
  }

  generarReporteProduccion(): void {
    const nuevoReporte: Reporte = {
      id: Date.now(),
      tipo: 'Producción',
      descripcion: 'Reporte de órdenes de producción',
      fecha: new Date(),
      estado: 'generando',
      comando: 'Generación manual - Reporte de Producción'
    };
    
    this.reportes.unshift(nuevoReporte);
    this.toastr.info('Generando reporte de producción...', 'Procesando');
    
    this.reportesService.getReporteProduccion().subscribe({
      next: (data) => {
        nuevoReporte.estado = 'completado';
        nuevoReporte.datosReporte = data;
        this.toastr.success('Reporte de producción generado', 'Completado');
      },
      error: (err) => {
        nuevoReporte.estado = 'error';
        nuevoReporte.descripcion += ' (Error al generar)';
        this.toastr.error('Error al generar reporte de producción', 'Error');
        console.error(err);
      }
    });
  }

  generarReporteClientes(): void {
    const nuevoReporte: Reporte = {
      id: Date.now(),
      tipo: 'Clientes',
      descripcion: 'Reporte de clientes registrados',
      fecha: new Date(),
      estado: 'generando',
      comando: 'Generación manual - Reporte de Clientes'
    };
    
    this.reportes.unshift(nuevoReporte);
    this.toastr.info('Generando reporte de clientes...', 'Procesando');
    
    this.reportesService.getReporteClientes().subscribe({
      next: (data) => {
        nuevoReporte.estado = 'completado';
        nuevoReporte.datosReporte = data;
        this.toastr.success('Reporte de clientes generado', 'Completado');
      },
      error: (err) => {
        nuevoReporte.estado = 'error';
        nuevoReporte.descripcion += ' (Error al generar)';
        this.toastr.error('Error al generar reporte de clientes', 'Error');
        console.error(err);
      }
    });
  }

  generarReporteBitacora(): void {
    const nuevoReporte: Reporte = {
      id: Date.now(),
      tipo: 'Bitácora',
      descripcion: 'Reporte de actividades del sistema',
      fecha: new Date(),
      estado: 'generando',
      comando: 'Generación manual - Reporte de Bitácora'
    };
    
    this.reportes.unshift(nuevoReporte);
    this.toastr.info('Generando reporte de bitácora...', 'Procesando');
    
    this.reportesService.getReporteBitacora().subscribe({
      next: (data) => {
        nuevoReporte.estado = 'completado';
        nuevoReporte.datosReporte = data;
        this.toastr.success('Reporte de bitácora generado', 'Completado');
      },
      error: (err) => {
        nuevoReporte.estado = 'error';
        nuevoReporte.descripcion += ' (Error al generar)';
        this.toastr.error('Error al generar reporte de bitácora', 'Error');
        console.error(err);
      }
    });
  }

  generarReportePersonal(): void {
    const nuevoReporte: Reporte = {
      id: Date.now(),
      tipo: 'Personal',
      descripcion: 'Reporte de empleados y personal',
      fecha: new Date(),
      estado: 'generando',
      comando: 'Generación manual - Reporte de Personal'
    };
    
    this.reportes.unshift(nuevoReporte);
    this.toastr.info('Generando reporte de personal...', 'Procesando');
    
    this.reportesService.getReportePersonal().subscribe({
      next: (data) => {
        nuevoReporte.estado = 'completado';
        nuevoReporte.datosReporte = data;
        this.toastr.success('Reporte de personal generado', 'Completado');
      },
      error: (err) => {
        nuevoReporte.estado = 'error';
        nuevoReporte.descripcion += ' (Error al generar)';
        this.toastr.error('Error al generar reporte de personal', 'Error');
        console.error(err);
      }
    });
  }

  generarReportePedidos(): void {
    const nuevoReporte: Reporte = {
      id: Date.now(),
      tipo: 'Pedidos',
      descripcion: 'Reporte de pedidos realizados',
      fecha: new Date(),
      estado: 'generando',
      comando: 'Generación manual - Reporte de Pedidos'
    };
    
    this.reportes.unshift(nuevoReporte);
    this.toastr.info('Generando reporte de pedidos...', 'Procesando');
    
    this.reportesService.getReportePedidos().subscribe({
      next: (data) => {
        nuevoReporte.estado = 'completado';
        nuevoReporte.datosReporte = data;
        this.toastr.success('Reporte de pedidos generado', 'Completado');
      },
      error: (err) => {
        nuevoReporte.estado = 'error';
        nuevoReporte.descripcion += ' (Error al generar)';
        this.toastr.error('Error al generar reporte de pedidos', 'Error');
        console.error(err);
      }
    });
  }

  procesarComandoManual(): void {
    if (!this.comandoActual.trim()) {
      this.toastr.warning('Por favor, escribe un comando', 'Atención');
      return;
    }
    
    this.procesarComando(this.comandoActual);
    this.comandoActual = '';
  }

  descargarReporte(reporte: Reporte): void {
    if (reporte.estado !== 'completado') {
      this.toastr.warning('El reporte aún no está disponible', 'Atención');
      return;
    }
    
    // Normaliza el tipo para evitar problemas de tildes/mayúsculas
    const tipo = (reporte.tipo || '').toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
    
    // Mapeo de tipos a endpoints del backend
    let endpoint = '';
    switch (tipo) {
      case 'inventario':
        endpoint = 'inventario-consumo';
        break;
      case 'ventas':
        endpoint = 'ventas';
        break;
      case 'produccion':
        endpoint = 'produccion';
        break;
      case 'clientes':
        endpoint = 'clientes';
        break;
      case 'bitacora':
        endpoint = 'bitacora';
        break;
      case 'personal':
        endpoint = 'personal';
        break;
      case 'pedidos':
        endpoint = 'pedidos';
        break;
      default:
        this.toastr.warning('Tipo de reporte no soportado', 'Atención');
        return;
    }
    
    // Descargar Excel desde el backend
    this.descargarExcelDesdeBackend(endpoint);
  }

  descargarPDF(reporte: Reporte): void {
    if (reporte.estado !== 'completado') {
      this.toastr.warning('El reporte aún no está disponible', 'Atención');
      return;
    }
    if (!reporte.datosReporte) {
      this.toastr.warning('No hay datos disponibles para descargar', 'Atención');
      return;
    }
    // Normaliza el tipo para evitar problemas de tildes/mayúsculas
    const tipo = (reporte.tipo || '').toLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '');
    switch (tipo) {
      case 'inventario':
        this.descargarPDFDesdeBackend('inventario-consumo');
        break;
      case 'ventas':
        this.descargarPDFDesdeBackend('ventas');
        break;
      case 'produccion':
        this.descargarPDFDesdeBackend('produccion');
        break;
      case 'clientes':
        this.descargarPDFDesdeBackend('clientes');
        break;
      case 'bitacora':
        this.descargarPDFDesdeBackend('bitacora');
        break;
      case 'personal':
        this.descargarPDFDesdeBackend('personal');
        break;
      case 'pedidos':
        this.descargarPDFDesdeBackend('pedidos');
        break;
      default:
        this.toastr.warning('Tipo de reporte no soportado', 'Atención');
    }
  }

  // ========== DESCARGA DE PDF DESDE BACKEND ==========
  
  private descargarPDFDesdeBackend(tipoReporte: string): void {
    const url = `${environment.endpoint}api/reportes/${tipoReporte}/?formato=pdf`;
    
    this.http.get(url, { responseType: 'blob' }).subscribe({
      next: (blob: Blob) => {
        const link = document.createElement('a');
        const urlBlob = window.URL.createObjectURL(blob);
        link.href = urlBlob;
        link.download = `Reporte_${tipoReporte}_${new Date().toISOString().split('T')[0]}.pdf`;
        link.click();
        window.URL.revokeObjectURL(urlBlob);
        this.toastr.success(`Reporte de ${tipoReporte} descargado en PDF`, 'Descarga completada');
      },
      error: (error: any) => {
        console.error('Error al descargar PDF:', error);
        this.toastr.error('Error al descargar el reporte PDF', 'Error');
      }
    });
  }

  private descargarExcelDesdeBackend(tipoReporte: string): void {
    const url = `${environment.endpoint}api/reportes/${tipoReporte}/?formato=excel`;
    
    this.http.get(url, { responseType: 'blob' }).subscribe({
      next: (blob: Blob) => {
        const link = document.createElement('a');
        const urlBlob = window.URL.createObjectURL(blob);
        link.href = urlBlob;
        link.download = `Reporte_${tipoReporte}_${new Date().toISOString().split('T')[0]}.xlsx`;
        link.click();
        window.URL.revokeObjectURL(urlBlob);
        this.toastr.success(`Reporte de ${tipoReporte} descargado en Excel`, 'Descarga completada');
      },
      error: (error: any) => {
        console.error('Error al descargar Excel:', error);
        this.toastr.error('Error al descargar el reporte Excel', 'Error');
      }
    });
  }

  // ========== DESCARGA DE REPORTES EN EXCEL (MÉTODOS ANTIGUOS - YA NO SE USAN) ==========

  private descargarReporteInventarioExcel(data: any): void {
    const workbook = XLSX.utils.book_new();

    // Hoja de información
    const infoData = [
      ['REPORTE DE INVENTARIO Y CONSUMO'],
      ['ManufacturaPRO'],
      ['Fecha de Generación:', new Date(data.fecha_generacion).toLocaleString('es-ES')],
      ['']
    ];
    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja de Materias Primas
    const materiasData = [
      ['STOCK DE MATERIAS PRIMAS'],
      [''],
      ['Materia Prima', 'Stock Total', 'Unidad de Medida'],
      ...data.stock_materias_primas.map((item: any) => [
        item.nombre_materia_prima,
        item.stock_total,
        item.unidad_medida
      ])
    ];
    const wsMaterias = XLSX.utils.aoa_to_sheet(materiasData);
    XLSX.utils.book_append_sheet(workbook, wsMaterias, 'Materias Primas');

    // Hoja de Productos Terminados
    const productosData = [
      ['STOCK DE PRODUCTOS TERMINADOS'],
      [''],
      ['Producto', 'Cantidad'],
      ...data.stock_productos_terminados.map((item: any) => [
        item.producto,
        item.cantidad
      ])
    ];
    const wsProductos = XLSX.utils.aoa_to_sheet(productosData);
    XLSX.utils.book_append_sheet(workbook, wsProductos, 'Productos Terminados');

    // Hoja de Consumo
    const consumoData = [
      ['CONSUMO DE MATERIALES'],
      [''],
      ['Materia Prima', 'Consumo Total', 'Unidad de Medida'],
      ...data.consumo_materiales.data.map((item: any) => [
        item.nombre_materia,
        item.consumo_total,
        item.unidad_medida
      ])
    ];
    const wsConsumo = XLSX.utils.aoa_to_sheet(consumoData);
    XLSX.utils.book_append_sheet(workbook, wsConsumo, 'Consumo Materiales');

    // Guardar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Inventario_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
    this.toastr.success('Reporte de inventario descargado', 'Descarga completada');
  }

  private descargarReporteVentasExcel(data: any): void {
    const workbook = XLSX.utils.book_new();

    // Hoja de información
    const infoData = [
      ['REPORTE DE VENTAS'],
      ['ManufacturaPRO'],
      ['Fecha de Generación:', new Date(data.fecha_generacion).toLocaleString('es-ES')],
      ['']
    ];
    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja de Ventas
    const ventasData = [
      ['DETALLE DE VENTAS'],
      [''],
      ['ID Salida', 'Fecha', 'Responsable', 'Producto', 'Lote', 'Cantidad', 'Estado'],
      ...data.ventas.map((item: any) => [
        item.id_salida,
        item.fecha_salida,
        item.responsable,
        item.producto,
        item.lote_asociado,
        item.cantidad,
        item.estado
      ])
    ];
    const wsVentas = XLSX.utils.aoa_to_sheet(ventasData);
    XLSX.utils.book_append_sheet(workbook, wsVentas, 'Ventas');

    // Hoja de Resumen
    const resumenData = [
      ['RESUMEN DE VENTAS'],
      [''],
      ['Descripción', 'Valor'],
      ['Total de Ventas', data.estadisticas.total_ventas],
      ['Cantidad Total', data.estadisticas.cantidad_total]
    ];
    const wsResumen = XLSX.utils.aoa_to_sheet(resumenData);
    XLSX.utils.book_append_sheet(workbook, wsResumen, 'Resumen');

    // Guardar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Ventas_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
    this.toastr.success('Reporte de ventas descargado', 'Descarga completada');
  }

  private descargarReporteProduccionExcel(data: any): void {
    const workbook = XLSX.utils.book_new();

    // Hoja de información
    const infoData = [
      ['REPORTE DE PRODUCCIÓN'],
      ['ManufacturaPRO'],
      ['Fecha de Generación:', new Date(data.fecha_generacion).toLocaleString('es-ES')],
      ['']
    ];
    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja de Órdenes
    const ordenesData = [
      ['ÓRDENES DE PRODUCCIÓN'],
      [''],
      ['ID', 'Código', 'Fecha Inicio', 'Fecha Fin', 'Producto', 'Color', 'Talla', 'Cantidad', 'Estado'],
      ...data.ordenes.map((item: any) => [
        item.id_orden,
        item.cod_orden,
        item.fecha_inicio,
        item.fecha_fin,
        item.producto_modelo,
        item.color,
        item.talla,
        item.cantidad_total,
        item.estado
      ])
    ];
    const wsOrdenes = XLSX.utils.aoa_to_sheet(ordenesData);
    XLSX.utils.book_append_sheet(workbook, wsOrdenes, 'Órdenes');

    // Hoja de Estadísticas
    const estadisticasData = [
      ['ESTADÍSTICAS DE PRODUCCIÓN'],
      [''],
      ['Descripción', 'Valor'],
      ['Total de Órdenes', data.estadisticas.total_ordenes],
      ['Completadas', data.estadisticas.completadas],
      ['En Proceso', data.estadisticas.en_proceso],
      ['Retrasadas', data.estadisticas.retrasadas],
      ['Cantidad Total Producida', data.estadisticas.cantidad_total_producida]
    ];
    const wsEstadisticas = XLSX.utils.aoa_to_sheet(estadisticasData);
    XLSX.utils.book_append_sheet(workbook, wsEstadisticas, 'Estadísticas');

    // Guardar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Produccion_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
    this.toastr.success('Reporte de producción descargado', 'Descarga completada');
  }

  private descargarReporteClientesExcel(data: any): void {
    const workbook = XLSX.utils.book_new();

    // Hoja de información
    const infoData = [
      ['REPORTE DE CLIENTES'],
      ['ManufacturaPRO'],
      ['Fecha de Generación:', new Date(data.fecha_generacion).toLocaleString('es-ES')],
      ['']
    ];
    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja de Clientes
    const clientesData = [
      ['LISTADO DE CLIENTES'],
      [''],
      ['ID', 'Nombre Completo', 'Dirección', 'Teléfono', 'Fecha Nacimiento', 'Estado', 'Email'],
      ...data.clientes.map((item: any) => [
        item.id,
        item.nombre_completo,
        item.direccion,
        item.telefono,
        item.fecha_nacimiento,
        item.estado,
        item.email || 'N/A'
      ])
    ];
    const wsClientes = XLSX.utils.aoa_to_sheet(clientesData);
    XLSX.utils.book_append_sheet(workbook, wsClientes, 'Clientes');

    // Hoja de Estadísticas
    const estadisticasData = [
      ['ESTADÍSTICAS DE CLIENTES'],
      [''],
      ['Descripción', 'Valor'],
      ['Total de Clientes', data.estadisticas.total_clientes],
      ['Clientes Activos', data.estadisticas.activos],
      ['Clientes Inactivos', data.estadisticas.inactivos],
      ['Nuevos este Mes', data.estadisticas.nuevos_mes_actual || 0]
    ];
    const wsEstadisticas = XLSX.utils.aoa_to_sheet(estadisticasData);
    XLSX.utils.book_append_sheet(workbook, wsEstadisticas, 'Estadísticas');

    // Guardar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Clientes_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
    this.toastr.success('Reporte de clientes descargado', 'Descarga completada');
  }

  private descargarReporteBitacoraExcel(data: any): void {
    const workbook = XLSX.utils.book_new();

    // Hoja de información
    const infoData = [
      ['REPORTE DE BITÁCORA'],
      ['ManufacturaPRO'],
      ['Fecha de Generación:', new Date(data.fecha_generacion).toLocaleString('es-ES')],
      ['']
    ];
    
    if (data.filtros) {
      if (data.filtros.fecha_inicio) infoData.push(['Fecha Inicio:', data.filtros.fecha_inicio]);
      if (data.filtros.fecha_fin) infoData.push(['Fecha Fin:', data.filtros.fecha_fin]);
      if (data.filtros.usuario) infoData.push(['Usuario:', data.filtros.usuario]);
    }
    
    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja de Actividades
    const actividadesData = [
      ['HISTORIAL DE ACTIVIDADES'],
      [''],
      ['Usuario', 'IP', 'Fecha y Hora', 'Acción', 'Descripción'],
      ...data.actividades.map((item: any) => [
        item.username,
        item.ip,
        item.fecha_hora,
        item.accion,
        item.descripcion
      ])
    ];
    const wsActividades = XLSX.utils.aoa_to_sheet(actividadesData);
    XLSX.utils.book_append_sheet(workbook, wsActividades, 'Actividades');

    // Hoja de Estadísticas
    const estadisticasData = [
      ['ESTADÍSTICAS DE BITÁCORA'],
      [''],
      ['Descripción', 'Valor'],
      ['Total de Actividades', data.estadisticas.total_actividades],
      ['Usuarios Activos', data.estadisticas.usuarios_activos],
      ['Acciones Críticas', data.estadisticas.acciones_criticas || 0]
    ];
    const wsEstadisticas = XLSX.utils.aoa_to_sheet(estadisticasData);
    XLSX.utils.book_append_sheet(workbook, wsEstadisticas, 'Estadísticas');

    // Guardar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Bitacora_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
    this.toastr.success('Reporte de bitácora descargado', 'Descarga completada');
  }

  private descargarReportePersonalExcel(data: any): void {
    const workbook = XLSX.utils.book_new();

    // Hoja de información
    const infoData = [
      ['REPORTE DE PERSONAL'],
      ['ManufacturaPRO'],
      ['Fecha de Generación:', new Date(data.fecha_generacion).toLocaleString('es-ES')],
      ['']
    ];
    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja de Empleados
    const empleadosData = [
      ['LISTADO DE EMPLEADOS'],
      [''],
      ['ID', 'Nombre Completo', 'CI', 'Teléfono', 'Rol', 'Fecha Contratación', 'Salario', 'Estado'],
      ...data.empleados.map((item: any) => [
        item.id,
        item.nombre_completo,
        item.ci,
        item.telefono,
        item.rol,
        item.fecha_contratacion,
        item.salario || 'N/A',
        item.estado
      ])
    ];
    const wsEmpleados = XLSX.utils.aoa_to_sheet(empleadosData);
    XLSX.utils.book_append_sheet(workbook, wsEmpleados, 'Empleados');

    // Hoja de Estadísticas
    const estadisticasData = [
      ['ESTADÍSTICAS DE PERSONAL'],
      [''],
      ['Descripción', 'Valor'],
      ['Total de Empleados', data.estadisticas.total_empleados],
      ['Empleados Activos', data.estadisticas.activos],
      ['Empleados Inactivos', data.estadisticas.inactivos]
    ];
    
    if (data.estadisticas.salario_total) {
      estadisticasData.push(['Salario Total', data.estadisticas.salario_total]);
    }
    
    const wsEstadisticas = XLSX.utils.aoa_to_sheet(estadisticasData);
    XLSX.utils.book_append_sheet(workbook, wsEstadisticas, 'Estadísticas');

    // Hoja de Distribución por Rol
    if (data.estadisticas.por_rol) {
      const roleData = [
        ['DISTRIBUCIÓN POR ROL'],
        [''],
        ['Rol', 'Cantidad'],
        ...Object.entries(data.estadisticas.por_rol).map(([rol, cantidad]) => [rol, cantidad])
      ];
      const wsRoles = XLSX.utils.aoa_to_sheet(roleData);
      XLSX.utils.book_append_sheet(workbook, wsRoles, 'Por Rol');
    }

    // Guardar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Personal_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
    this.toastr.success('Reporte de personal descargado', 'Descarga completada');
  }

  private descargarReportePedidosExcel(data: any): void {
    const workbook = XLSX.utils.book_new();

    // Hoja de información
    const infoData = [
      ['REPORTE DE PEDIDOS'],
      ['ManufacturaPRO'],
      ['Fecha de Generación:', new Date(data.fecha_generacion).toLocaleString('es-ES')],
      ['']
    ];
    
    if (data.filtros) {
      if (data.filtros.fecha_inicio) infoData.push(['Fecha Inicio:', data.filtros.fecha_inicio]);
      if (data.filtros.fecha_fin) infoData.push(['Fecha Fin:', data.filtros.fecha_fin]);
      if (data.filtros.estado) infoData.push(['Estado:', data.filtros.estado]);
    }
    
    const wsInfo = XLSX.utils.aoa_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, wsInfo, 'Información');

    // Hoja de Pedidos
    const pedidosData = [
      ['LISTADO DE PEDIDOS'],
      [''],
      ['ID', 'Código', 'Cliente', 'Fecha Pedido', 'Fecha Entrega', 'Estado', 'Total', 'Productos'],
      ...data.pedidos.map((item: any) => [
        item.id,
        item.codigo_pedido,
        item.cliente,
        item.fecha_pedido,
        item.fecha_entrega || 'N/A',
        item.estado,
        item.total,
        item.productos_count || 'N/A'
      ])
    ];
    const wsPedidos = XLSX.utils.aoa_to_sheet(pedidosData);
    XLSX.utils.book_append_sheet(workbook, wsPedidos, 'Pedidos');

    // Hoja de Estadísticas
    const estadisticasData = [
      ['ESTADÍSTICAS DE PEDIDOS'],
      [''],
      ['Descripción', 'Valor'],
      ['Total de Pedidos', data.estadisticas.total_pedidos],
      ['Pendientes', data.estadisticas.pendientes],
      ['Completados', data.estadisticas.completados],
      ['Cancelados', data.estadisticas.cancelados],
      ['Monto Total', `Bs. ${data.estadisticas.monto_total.toFixed(2)}`]
    ];
    const wsEstadisticas = XLSX.utils.aoa_to_sheet(estadisticasData);
    XLSX.utils.book_append_sheet(workbook, wsEstadisticas, 'Estadísticas');

    // Guardar archivo
    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileName = `Reporte_Pedidos_${new Date().toISOString().split('T')[0]}.xlsx`;
    saveAs(blob, fileName);
    this.toastr.success('Reporte de pedidos descargado', 'Descarga completada');
  }



  private descargarReporteVentasPDF(data: any): void {
    const doc = new jsPDF();
    
    // Encabezado
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('REPORTE DE VENTAS', 105, 15, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text('ManufacturaPRO', 105, 22, { align: 'center' });
    
    doc.setFontSize(10);
    doc.text(`Fecha de Generación: ${new Date(data.fecha_generacion).toLocaleString('es-ES')}`, 14, 30);
    
    // Información de filtros si existen
    let yPos = 40;
    if (data.filtros) {
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text('Filtros Aplicados:', 14, yPos);
      doc.setFont('helvetica', 'normal');
      yPos += 6;
      
      if (data.filtros.fecha_inicio) {
        doc.text(`Desde: ${data.filtros.fecha_inicio}`, 14, yPos);
        yPos += 6;
      }
      if (data.filtros.fecha_fin) {
        doc.text(`Hasta: ${data.filtros.fecha_fin}`, 14, yPos);
        yPos += 6;
      }
      yPos += 4;
    }
    
    // Tabla de Ventas
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('LISTADO DE VENTAS', 14, yPos);
    yPos += 5;
    
    const ventasTableData = data.ventas.map((item: any) => [
      item.id,
      item.fecha,
      item.cliente || 'N/A',
      item.producto || 'N/A',
      item.cantidad || 0,
      `Bs. ${item.total?.toFixed(2) || '0.00'}`
    ]);
    
    autoTable(doc, {
      startY: yPos,
      head: [['ID', 'Fecha', 'Cliente', 'Producto', 'Cantidad', 'Total']],
      body: ventasTableData,
      theme: 'striped',
      headStyles: { fillColor: [59, 130, 246] },
      styles: { fontSize: 8, cellPadding: 2 },
      columnStyles: {
        0: { cellWidth: 15 },
        1: { cellWidth: 25 },
        2: { cellWidth: 40 },
        3: { cellWidth: 40 },
        4: { cellWidth: 20, halign: 'center' },
        5: { cellWidth: 30, halign: 'right' }
      }
    });
    
    // Estadísticas
    const finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('RESUMEN Y ESTADÍSTICAS', 14, finalY);
    
    const estadisticasData = [
      ['Total de Ventas', data.estadisticas.total_ventas || 0],
      ['Total Ingresos', `Bs. ${data.estadisticas.total_ingresos?.toFixed(2) || '0.00'}`],
      ['Productos Vendidos', data.estadisticas.productos_vendidos || 0]
    ];
    
    autoTable(doc, {
      startY: finalY + 5,
      head: [['Descripción', 'Valor']],
      body: estadisticasData,
      theme: 'plain',
      headStyles: { fillColor: [229, 231, 235], textColor: [0, 0, 0], fontStyle: 'bold' },
      styles: { fontSize: 9, cellPadding: 3 },
      columnStyles: {
        0: { cellWidth: 100, fontStyle: 'bold' },
        1: { cellWidth: 70, halign: 'right' }
      }
    });
    
    // Guardar
    const fileName = `Reporte_Ventas_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
    this.toastr.success('Reporte de ventas descargado en PDF', 'Descarga completada');
  }

  private descargarReporteInventarioPDF(data: any): void {
    const doc = new jsPDF();
    
    // Encabezado
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('REPORTE DE INVENTARIO', 105, 15, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text('ManufacturaPRO', 105, 22, { align: 'center' });
    
    doc.setFontSize(10);
    doc.text(`Fecha de Generación: ${new Date(data.fecha_generacion).toLocaleString('es-ES')}`, 14, 30);
    
    // Tabla de Materias Primas
    let yPos = 40;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('STOCK DE MATERIAS PRIMAS', 14, yPos);
    yPos += 5;
    
    const materiasData = data.stock_materias_primas.map((item: any) => [
      item.nombre_materia_prima,
      item.stock_total,
      item.unidad_medida
    ]);
    
    autoTable(doc, {
      startY: yPos,
      head: [['Materia Prima', 'Stock Total', 'Unidad']],
      body: materiasData,
      theme: 'striped',
      headStyles: { fillColor: [34, 197, 94] },
      styles: { fontSize: 8, cellPadding: 2 }
    });
    
    // Tabla de Productos Terminados
    let finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('STOCK DE PRODUCTOS TERMINADOS', 14, finalY);
    
    const productosData = data.stock_productos_terminados.map((item: any) => [
      item.producto,
      item.cantidad
    ]);
    
    autoTable(doc, {
      startY: finalY + 5,
      head: [['Producto', 'Cantidad']],
      body: productosData,
      theme: 'striped',
      headStyles: { fillColor: [34, 197, 94] },
      styles: { fontSize: 8, cellPadding: 2 }
    });
    
    // Guardar
    const fileName = `Reporte_Inventario_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
    this.toastr.success('Reporte de inventario descargado en PDF', 'Descarga completada');
  }

  private descargarReporteProduccionPDF(data: any): void {
    const doc = new jsPDF();
    
    // Encabezado
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('REPORTE DE PRODUCCIÓN', 105, 15, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text('ManufacturaPRO', 105, 22, { align: 'center' });
    
    doc.setFontSize(10);
    doc.text(`Fecha de Generación: ${new Date(data.fecha_generacion).toLocaleString('es-ES')}`, 14, 30);
    
    // Tabla de Órdenes
    let yPos = 40;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('ÓRDENES DE PRODUCCIÓN', 14, yPos);
    yPos += 5;
    
    const ordenesData = data.ordenes_produccion.map((item: any) => [
      item.codigo_orden,
      item.fecha_creacion,
      item.producto,
      item.cantidad_requerida,
      item.estado
    ]);
    
    autoTable(doc, {
      startY: yPos,
      head: [['Código', 'Fecha', 'Producto', 'Cantidad', 'Estado']],
      body: ordenesData,
      theme: 'striped',
  headStyles: { fillColor: [59, 130, 246] },
      styles: { fontSize: 8, cellPadding: 2 }
    });
    
    // Estadísticas
    const finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('ESTADÍSTICAS DE PRODUCCIÓN', 14, finalY);
    
    const estadisticasData = [
      ['Total de Órdenes', data.estadisticas.total_ordenes || 0],
      ['Completadas', data.estadisticas.completadas || 0],
      ['En Proceso', data.estadisticas.en_proceso || 0],
      ['Pendientes', data.estadisticas.pendientes || 0]
    ];
    
    autoTable(doc, {
      startY: finalY + 5,
      head: [['Descripción', 'Valor']],
      body: estadisticasData,
      theme: 'plain',
      headStyles: { fillColor: [229, 231, 235], textColor: [0, 0, 0], fontStyle: 'bold' },
      styles: { fontSize: 9, cellPadding: 3 }
    });
    
    // Guardar
    const fileName = `Reporte_Produccion_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
    this.toastr.success('Reporte de producción descargado en PDF', 'Descarga completada');
  }

  private descargarReporteClientesPDF(data: any): void {
    const doc = new jsPDF();
    
    // Encabezado
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('REPORTE DE CLIENTES', 105, 15, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text('ManufacturaPRO', 105, 22, { align: 'center' });
    
    doc.setFontSize(10);
    doc.text(`Fecha de Generación: ${new Date(data.fecha_generacion).toLocaleString('es-ES')}`, 14, 30);
    
    // Tabla de Clientes
    let yPos = 40;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('LISTADO DE CLIENTES', 14, yPos);
    yPos += 5;
    
    const clientesData = data.clientes.map((item: any) => [
      item.id,
      item.nombre_completo,
      item.telefono,
      item.estado
    ]);
    
    autoTable(doc, {
      startY: yPos,
      head: [['ID', 'Nombre Completo', 'Teléfono', 'Estado']],
      body: clientesData,
      theme: 'striped',
      headStyles: { fillColor: [234, 179, 8] },
      styles: { fontSize: 8, cellPadding: 2 }
    });
    
    // Estadísticas
    const finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('ESTADÍSTICAS', 14, finalY);
    
    const estadisticasData = [
      ['Total de Clientes', data.estadisticas.total_clientes || 0],
      ['Activos', data.estadisticas.activos || 0],
      ['Inactivos', data.estadisticas.inactivos || 0]
    ];
    
    autoTable(doc, {
      startY: finalY + 5,
      head: [['Descripción', 'Valor']],
      body: estadisticasData,
      theme: 'plain',
      headStyles: { fillColor: [229, 231, 235], textColor: [0, 0, 0], fontStyle: 'bold' },
      styles: { fontSize: 9, cellPadding: 3 }
    });
    
    // Guardar
    const fileName = `Reporte_Clientes_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
    this.toastr.success('Reporte de clientes descargado en PDF', 'Descarga completada');
  }

  private descargarReporteBitacoraPDF(data: any): void {
    const doc = new jsPDF();
    
    // Encabezado
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('REPORTE DE BITÁCORA', 105, 15, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text('ManufacturaPRO', 105, 22, { align: 'center' });
    
    doc.setFontSize(10);
    doc.text(`Fecha de Generación: ${new Date(data.fecha_generacion).toLocaleString('es-ES')}`, 14, 30);
    
    // Tabla de Actividades
    let yPos = 40;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('HISTORIAL DE ACTIVIDADES', 14, yPos);
    yPos += 5;
    
    const actividadesData = data.actividades.map((item: any) => [
      item.username,
      item.fecha_hora,
      item.accion,
      item.descripcion.substring(0, 40) + '...'
    ]);
    
    autoTable(doc, {
      startY: yPos,
      head: [['Usuario', 'Fecha/Hora', 'Acción', 'Descripción']],
      body: actividadesData,
      theme: 'striped',
      headStyles: { fillColor: [239, 68, 68] },
      styles: { fontSize: 7, cellPadding: 2 }
    });
    
    // Estadísticas
    const finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('ESTADÍSTICAS', 14, finalY);
    
    const estadisticasData = [
      ['Total de Actividades', data.estadisticas.total_actividades || 0],
      ['Usuarios Activos', data.estadisticas.usuarios_activos || 0]
    ];
    
    autoTable(doc, {
      startY: finalY + 5,
      head: [['Descripción', 'Valor']],
      body: estadisticasData,
      theme: 'plain',
      headStyles: { fillColor: [229, 231, 235], textColor: [0, 0, 0], fontStyle: 'bold' },
      styles: { fontSize: 9, cellPadding: 3 }
    });
    
    // Guardar
    const fileName = `Reporte_Bitacora_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
    this.toastr.success('Reporte de bitácora descargado en PDF', 'Descarga completada');
  }

  private descargarReportePersonalPDF(data: any): void {
    const doc = new jsPDF();
    
    // Encabezado
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('REPORTE DE PERSONAL', 105, 15, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text('ManufacturaPRO', 105, 22, { align: 'center' });
    
    doc.setFontSize(10);
    doc.text(`Fecha de Generación: ${new Date(data.fecha_generacion).toLocaleString('es-ES')}`, 14, 30);
    
    // Tabla de Empleados
    let yPos = 40;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('LISTADO DE EMPLEADOS', 14, yPos);
    yPos += 5;
    
    const empleadosData = data.empleados.map((item: any) => [
      item.id,
      item.nombre_completo,
      item.ci,
      item.rol,
      item.estado
    ]);
    
    autoTable(doc, {
      startY: yPos,
      head: [['ID', 'Nombre Completo', 'CI', 'Rol', 'Estado']],
      body: empleadosData,
      theme: 'striped',
      headStyles: { fillColor: [20, 184, 166] },
      styles: { fontSize: 8, cellPadding: 2 }
    });
    
    // Estadísticas
    const finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('ESTADÍSTICAS', 14, finalY);
    
    const estadisticasData = [
      ['Total de Empleados', data.estadisticas.total_empleados || 0],
      ['Activos', data.estadisticas.activos || 0],
      ['Inactivos', data.estadisticas.inactivos || 0]
    ];
    
    autoTable(doc, {
      startY: finalY + 5,
      head: [['Descripción', 'Valor']],
      body: estadisticasData,
      theme: 'plain',
      headStyles: { fillColor: [229, 231, 235], textColor: [0, 0, 0], fontStyle: 'bold' },
      styles: { fontSize: 9, cellPadding: 3 }
    });
    
    // Guardar
    const fileName = `Reporte_Personal_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
    this.toastr.success('Reporte de personal descargado en PDF', 'Descarga completada');
  }

  private descargarReportePedidosPDF(data: any): void {
    const doc = new jsPDF();
    
    // Encabezado
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('REPORTE DE PEDIDOS', 105, 15, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text('ManufacturaPRO', 105, 22, { align: 'center' });
    
    doc.setFontSize(10);
    doc.text(`Fecha de Generación: ${new Date(data.fecha_generacion).toLocaleString('es-ES')}`, 14, 30);
    
    // Tabla de Pedidos
    let yPos = 40;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('LISTADO DE PEDIDOS', 14, yPos);
    yPos += 5;
    
    const pedidosData = data.pedidos.map((item: any) => [
      item.codigo_pedido,
      item.cliente,
      item.fecha_pedido,
      item.estado,
      `Bs. ${item.total?.toFixed(2) || '0.00'}`
    ]);
    
    autoTable(doc, {
      startY: yPos,
      head: [['Código', 'Cliente', 'Fecha', 'Estado', 'Total']],
      body: pedidosData,
      theme: 'striped',
      headStyles: { fillColor: [249, 115, 22] },
      styles: { fontSize: 8, cellPadding: 2 }
    });
    
    // Estadísticas
    const finalY = (doc as any).lastAutoTable.finalY + 10;
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('ESTADÍSTICAS', 14, finalY);
    
    const estadisticasData = [
      ['Total de Pedidos', data.estadisticas.total_pedidos || 0],
      ['Pendientes', data.estadisticas.pendientes || 0],
      ['Completados', data.estadisticas.completados || 0],
      ['Monto Total', `Bs. ${data.estadisticas.monto_total?.toFixed(2) || '0.00'}`]
    ];
    
    autoTable(doc, {
      startY: finalY + 5,
      head: [['Descripción', 'Valor']],
      body: estadisticasData,
      theme: 'plain',
      headStyles: { fillColor: [229, 231, 235], textColor: [0, 0, 0], fontStyle: 'bold' },
      styles: { fontSize: 9, cellPadding: 3 }
    });
    
    // Guardar
    const fileName = `Reporte_Pedidos_${new Date().toISOString().split('T')[0]}.pdf`;
    doc.save(fileName);
    this.toastr.success('Reporte de pedidos descargado en PDF', 'Descarga completada');
  }

  eliminarReporte(reporte: Reporte): void {
    if (!confirm(`¿Está seguro de eliminar el reporte "${reporte.tipo}"?`)) {
      return;
    }
    
    this.reportes = this.reportes.filter(r => r.id !== reporte.id);
    this.toastr.success('Reporte eliminado', 'Eliminado');
  }

  usarEjemplo(ejemplo: string): void {
    this.comandoActual = ejemplo;
    this.toastr.info('Ejemplo cargado. Puedes editarlo o ejecutarlo directamente', 'Comando sugerido');
  }

  limpiarHistorial(): void {
    if (confirm('¿Está seguro de limpiar todo el historial de comandos?')) {
      this.historialComandos = [];
      this.guardarHistorial();
      this.toastr.success('Historial limpiado', 'Completado');
    }
  }

  cargarHistorial(): void {
    const historial = localStorage.getItem('reportesIA_historial');
    if (historial) {
      try {
        this.historialComandos = JSON.parse(historial);
      } catch (error) {
        console.error('Error al cargar historial:', error);
      }
    }
  }

  guardarHistorial(): void {
    localStorage.setItem('reportesIA_historial', JSON.stringify(this.historialComandos));
  }

  get filtrados(): Reporte[] {
    const q = this.busqueda.trim().toLowerCase();
    
    return this.reportes.filter((r) => {
      const estadoOk = this.filtroEstado ? r.estado === this.filtroEstado : true;
      const text = `${r.tipo} ${r.descripcion} ${r.comando}`.toLowerCase();
      const buscaOk = q ? text.includes(q) : true;
      
      return estadoOk && buscaOk;
    });
  }

  getEstadoClass(estado: string): string {
    switch (estado) {
      case 'completado':
        return 'bg-green-100 text-green-800';
      case 'generando':
        return 'bg-yellow-100 text-yellow-800';
      case 'error':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  }

  getEstadoIcon(estado: string): string {
    switch (estado) {
      case 'completado':
        return 'fa-check-circle';
      case 'generando':
        return 'fa-spinner fa-spin';
      case 'error':
        return 'fa-exclamation-circle';
      default:
        return 'fa-question-circle';
    }
  }
}
