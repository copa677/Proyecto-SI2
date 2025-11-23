import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

// Interfaces para Inventario
export interface StockMateriaPrima {
  nombre_materia_prima: string;
  unidad_medida: string;
  stock_total: number;
  stock_minimo?: number;
  estado?: string;
}

export interface StockProductoTerminado {
  producto: string;
  cantidad: number;
}

export interface ConsumoMaterial {
  nombre_materia: string;
  unidad_medida: string;
  consumo_total: number;
}

export interface ReporteInventarioConsumo {
  fecha_generacion: string;
  stock_materias_primas: StockMateriaPrima[];
  stock_productos_terminados: StockProductoTerminado[];
  consumo_materiales: {
    filtros: { fecha_inicio: string | null; fecha_fin: string | null };
    data: ConsumoMaterial[];
  };
}

// Interfaces para Ventas
export interface VentaReporte {
  id_salida: number;
  fecha_salida: string;
  responsable: string;
  producto: string;
  lote_asociado: string;
  cantidad: number;
  unidad_medida: string;
  motivo: string;
  estado: string;
  precio_total: number;
}

export interface ReporteVentas {
  ventas: VentaReporte[];
  estadisticas: {
    total_ventas: number;
    cantidad_total: number;
    monto_total: number;
  };
  filtros: {
    fecha_inicio: string | null;
    fecha_fin: string | null;
  };
  fecha_generacion: string;
}

// Interfaces para Producción
export interface OrdenProduccionReporte {
  id_orden: number;
  cod_orden: string;
  fecha_inicio: string;
  fecha_fin: string;
  fecha_entrega: string;
  estado: string;
  producto_modelo: string;
  color: string;
  talla: string;
  cantidad_total: number;
  responsable: string;
  cumplimiento: string;
}

export interface ReporteProduccion {
  ordenes: OrdenProduccionReporte[];
  estadisticas: {
    total_ordenes: number;
    completadas: number;
    en_proceso: number;
    retrasadas: number;
    cantidad_total_producida: number;
  };
  filtros: {
    fecha_inicio: string | null;
    fecha_fin: string | null;
  };
  fecha_generacion: string;
}

// Interfaces para Clientes
export interface ClienteReporte {
  id: number;
  nombre_completo: string;
  direccion: string;
  telefono: string;
  fecha_nacimiento: string;
  estado: string;
  fecha_registro?: string;
  email?: string;
}

export interface ReporteClientes {
  clientes: ClienteReporte[];
  estadisticas: {
    total_clientes: number;
    activos: number;
    inactivos: number;
    nuevos_mes_actual: number;
  };
  fecha_generacion: string;
}

// Interfaces para Bitácora
export interface BitacoraReporte {
  id?: number;
  username: string;
  ip: string;
  fecha_hora: string;
  accion: string;
  descripcion: string;
}

export interface ReporteBitacora {
  actividades: BitacoraReporte[];
  estadisticas: {
    total_actividades: number;
    usuarios_activos: number;
    acciones_criticas: number;
  };
  filtros: {
    fecha_inicio: string | null;
    fecha_fin: string | null;
    usuario?: string | null;
  };
  fecha_generacion: string;
}

// Interfaces para Personal
export interface EmpleadoReporte {
  id: number;
  nombre_completo: string;
  telefono: string;
  ci: string;
  rol: string;
  direccion: string;
  fecha_contratacion: string;
  salario?: number;
  estado: string;
}

export interface ReportePersonal {
  empleados: EmpleadoReporte[];
  estadisticas: {
    total_empleados: number;
    activos: number;
    inactivos: number;
    por_rol: { [key: string]: number };
    salario_total?: number;
  };
  fecha_generacion: string;
}

// Interfaces para Pedidos
export interface PedidoReporte {
  id: number;
  codigo_pedido: string;
  cliente: string;
  fecha_pedido: string;
  fecha_entrega?: string;
  estado: string;
  total: number;
  productos_count?: number;
}

export interface ReportePedidos {
  pedidos: PedidoReporte[];
  estadisticas: {
    total_pedidos: number;
    pendientes: number;
    completados: number;
    cancelados: number;
    monto_total: number;
  };
  filtros: {
    fecha_inicio: string | null;
    fecha_fin: string | null;
    estado?: string | null;
  };
  fecha_generacion: string;
}

@Injectable({
  providedIn: 'root'
})
export class ReportesService {
  private apiUrl = `${environment.endpoint}/api/reportes`;

  constructor(private http: HttpClient) { }

  // Reporte de Inventario
  getReporteInventarioConsumo(fechaInicio?: string, fechaFin?: string): Observable<ReporteInventarioConsumo> {
    let params = new HttpParams();
    if (fechaInicio) params = params.set('fecha_inicio', fechaInicio);
    if (fechaFin) params = params.set('fecha_fin', fechaFin);

    return this.http.get<ReporteInventarioConsumo>(`${this.apiUrl}/inventario-consumo/`, { params });
  }

  // Reporte de Ventas
  getReporteVentas(fechaInicio?: string, fechaFin?: string): Observable<ReporteVentas> {
    let params = new HttpParams();
    if (fechaInicio) params = params.set('fecha_inicio', fechaInicio);
    if (fechaFin) params = params.set('fecha_fin', fechaFin);

    return this.http.get<ReporteVentas>(`${this.apiUrl}/ventas/`, { params });
  }

  // Reporte de Producción
  getReporteProduccion(fechaInicio?: string, fechaFin?: string): Observable<ReporteProduccion> {
    let params = new HttpParams();
    if (fechaInicio) params = params.set('fecha_inicio', fechaInicio);
    if (fechaFin) params = params.set('fecha_fin', fechaFin);

    return this.http.get<ReporteProduccion>(`${this.apiUrl}/produccion/`, { params });
  }

  // Reporte de Clientes
  getReporteClientes(): Observable<ReporteClientes> {
    return this.http.get<ReporteClientes>(`${this.apiUrl}/clientes/`);
  }

  // Reporte de Bitácora
  getReporteBitacora(fechaInicio?: string, fechaFin?: string, usuario?: string): Observable<ReporteBitacora> {
    let params = new HttpParams();
    if (fechaInicio) params = params.set('fecha_inicio', fechaInicio);
    if (fechaFin) params = params.set('fecha_fin', fechaFin);
    if (usuario) params = params.set('usuario', usuario);

    return this.http.get<ReporteBitacora>(`${this.apiUrl}/bitacora/`, { params });
  }

  // Reporte de Personal
  getReportePersonal(): Observable<ReportePersonal> {
    return this.http.get<ReportePersonal>(`${this.apiUrl}/personal/`);
  }

  // Reporte de Pedidos
  getReportePedidos(fechaInicio?: string, fechaFin?: string, estado?: string): Observable<ReportePedidos> {
    let params = new HttpParams();
    if (fechaInicio) params = params.set('fecha_inicio', fechaInicio);
    if (fechaFin) params = params.set('fecha_fin', fechaFin);
    if (estado) params = params.set('estado', estado);

    return this.http.get<ReportePedidos>(`${this.apiUrl}/pedidos/`, { params });
  }

  // Descargar PDF/Excel
  descargarReporte(tipo: 'ventas' | 'produccion' | 'inventario-consumo' | 'clientes' | 'bitacora' | 'personal' | 'pedidos', formato: 'pdf' | 'excel', fechaInicio?: string, fechaFin?: string): Observable<Blob> {
    let params = new HttpParams();
    params = params.set('formato', formato);
    if (fechaInicio) params = params.set('fecha_inicio', fechaInicio);
    if (fechaFin) params = params.set('fecha_fin', fechaFin);

    return this.http.get(`${this.apiUrl}/${tipo}/`, { params, responseType: 'blob' });
  }
}
