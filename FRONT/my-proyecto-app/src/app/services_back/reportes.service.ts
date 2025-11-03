import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

// Interfaces para tipar la respuesta de la API
export interface StockMateriaPrima {
  nombre_materia_prima: string;
  unidad_medida: string;
  stock_total: number;
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

@Injectable({
  providedIn: 'root'
})
export class ReportesService {
  private apiUrl = `${environment.endpoint}/reportes`;

  constructor(private http: HttpClient) { }

  getReporteInventarioConsumo(fechaInicio?: string, fechaFin?: string): Observable<ReporteInventarioConsumo> {
    let params = new HttpParams();
    if (fechaInicio) params = params.set('fecha_inicio', fechaInicio);
    if (fechaFin) params = params.set('fecha_fin', fechaFin);

    return this.http.get<ReporteInventarioConsumo>(`${this.apiUrl}/inventario-consumo/`, { params });
  }
}
