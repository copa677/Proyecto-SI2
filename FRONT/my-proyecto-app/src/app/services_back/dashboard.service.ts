import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

export interface KPIs {
  totalPersonal: number;
  asistenciaHoy: number;
  usuarios: number;
  ordenes: number;
  inventarioCritico: number;
  eficiencia: number;
}

export interface ActividadItem {
  titulo: string;
  detalle: string;
  hace: string;
  usuario: string;
}

export interface DashboardData {
  kpis: KPIs;
  actividad: ActividadItem[];
}

export interface OrdenReciente {
  id: number;
  producto: string;
  cantidad: number;
  estado: string;
  fecha_orden: string;
  fecha_entrega: string;
}

export interface ProductoCritico {
  id: number;
  nombre: string;
  cantidad: number;
  stock_minimo: number;
  unidad: string;
  deficit: number;
}

@Injectable({
  providedIn: 'root'
})
export class DashboardService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/dashboard';
  }

  // Obtener todas las estadísticas del dashboard
  getEstadisticas(): Observable<DashboardData> {
    return this.http.get<DashboardData>(`${this.myAppUrl}${this.myApiUrl}/estadisticas`);
  }

  // Obtener órdenes recientes
  getOrdenesRecientes(): Observable<OrdenReciente[]> {
    return this.http.get<OrdenReciente[]>(`${this.myAppUrl}${this.myApiUrl}/ordenes-recientes`);
  }

  // Obtener inventario crítico
  getInventarioCritico(): Observable<ProductoCritico[]> {
    return this.http.get<ProductoCritico[]>(`${this.myAppUrl}${this.myApiUrl}/inventario-critico`);
  }
}
