import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment.development';
import { OrdenProduccion } from 'src/interface/ordenProduccion';
import { Trazabilidad } from 'src/interface/trazabilidad'; // 🔹 nueva interfaz (asegúrate de crearla si no existe)

@Injectable({
  providedIn: 'root'
})
export class OrdenProduccionService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;            // URL base del backend
    this.myApiUrl = 'api/ordenproduccion/ordenes/';   // endpoint principal del backend
  }

  // ===========================
  // 🧾 ORDENES DE PRODUCCIÓN
  // ===========================

  // 🔹 Listar todas las órdenes de producción
  getOrdenesProduccion(): Observable<OrdenProduccion[]> {
    return this.http.get<OrdenProduccion[]>(`${this.myAppUrl}${this.myApiUrl}`);
  }

  // 🔹 Obtener una orden específica por su ID
  getOrdenProduccion(id_orden: number): Observable<OrdenProduccion> {
    return this.http.get<OrdenProduccion>(`${this.myAppUrl}${this.myApiUrl}${id_orden}/`);
  }

  // 🔹 Insertar una nueva orden
  insertarOrdenProduccion(nuevaOrden: OrdenProduccion): Observable<any> {
    return this.http.post<any>(`${this.myAppUrl}${this.myApiUrl}insertar/`, nuevaOrden);
  }

  // 🔹 Actualizar una orden existente
  actualizarOrdenProduccion(id_orden: number, ordenEditada: OrdenProduccion): Observable<any> {
    return this.http.put<any>(`${this.myAppUrl}${this.myApiUrl}actualizar/${id_orden}/`, ordenEditada);
  }

  // 🔹 Eliminar una orden
  eliminarOrdenProduccion(id_orden: number): Observable<any> {
    return this.http.delete<any>(`${this.myAppUrl}${this.myApiUrl}eliminar/${id_orden}/`);
  }

  // ===========================
  // 🧩 TRAZABILIDAD DE UNA ORDEN
  // ===========================

  getTrazabilidadPorOrden(id_orden: number): Observable<{
    orden: string;
    total_trazabilidades: number;
    trazabilidades: Trazabilidad[];
  }> {
    return this.http.get<{
      orden: string;
      total_trazabilidades: number;
      trazabilidades: Trazabilidad[];
    }>(`${this.myAppUrl}${this.myApiUrl}${id_orden}/trazabilidad/`);
  }
}
