import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

// Interfaces para las predicciones
export interface PrediccionPedido {
  fecha: string;
  cantidad: number;
  monto: number;
  confianza: number;
}

export interface PrediccionesResponse {
  mensaje: string;
  predicciones_ids: number[];
  predicciones: PrediccionPedido[];
}

export interface TendenciaMensual {
  mes: string;
  cantidad_pedidos: number;
  monto_total: number;
  promedio_pedido: number;
}

export interface Estadisticas {
  total_pedidos: number;
  promedio_monto: number;
  minimo_monto: number;
  maximo_monto: number;
  monto_total_anual: number;
  clientes_activos: number;
}

export interface ClienteTop {
  cliente: string;
  total_pedidos: number;
  monto_total: number;
}

export interface AnalisisTendencias {
  tendencias_mensuales: TendenciaMensual[];
  estadisticas: Estadisticas;
  clientes_top: ClienteTop[];
}

export interface MetricasModelo {
  modelo: {
    id: number;
    nombre: string;
    tipo: string;
    precision: number;
    fecha_entrenamiento: string;
    parametros: any;
  };
  predicciones_recientes: any[];
}

@Injectable({
  providedIn: 'root'
})
export class PrediccionesService {
  private apiUrl = `${environment.endpoint}/api/predicciones`;

  constructor(private http: HttpClient) { }

  /**
   * Realizar predicciones para los próximos meses
   * @param modeloId ID del modelo (fijo en 1)
   * @param mesesPrediccion Número de meses a predecir
   */
  predecirPedidos(modeloId: number = 1, mesesPrediccion: number = 6): Observable<PrediccionesResponse> {
    const body = {
      modelo_id: modeloId,
      meses_prediccion: mesesPrediccion
    };
    return this.http.post<PrediccionesResponse>(`${this.apiUrl}/modelo/predecir/`, body);
  }

  /**
   * Obtener análisis de tendencias históricas y estadísticas
   */
  getAnalisisTendencias(): Observable<AnalisisTendencias> {
    return this.http.get<AnalisisTendencias>(`${this.apiUrl}/analisis/tendencias/`);
  }

  /**
   * Obtener métricas de un modelo específico
   * @param modeloId ID del modelo (por defecto 1)
   */
  getMetricasModelo(modeloId: number = 1): Observable<MetricasModelo> {
    return this.http.get<MetricasModelo>(`${this.apiUrl}/modelo/${modeloId}/metricas/`);
  }

  /**
   * Entrenar un nuevo modelo
   * @param tipoModelo Tipo de modelo (regresion_lineal o random_forest)
   * @param mesesHistorico Meses de datos históricos a usar
   */
  entrenarModelo(tipoModelo: string = 'regresion_lineal', mesesHistorico: number = 12): Observable<any> {
    const body = {
      tipo_modelo: tipoModelo,
      meses_historico: mesesHistorico,
      parametros: {}
    };
    return this.http.post(`${this.apiUrl}/modelo/entrenar/`, body);
  }
}
