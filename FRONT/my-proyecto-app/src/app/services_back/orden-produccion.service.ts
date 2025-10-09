import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment.development';
import { OrdenProduccion } from 'src/interface/ordenProduccion';

@Injectable({
  providedIn: 'root'
})
export class OrdenProduccionService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;       // URL base del backend
    this.myApiUrl = 'api/ordenproduccion';      // endpoint principal Django
  }

  // ===========================
  // 🧾 ORDENES DE PRODUCCIÓN
  // ===========================

  // GET: listar todas las órdenes de producción
  getOrdenesProduccion(): Observable<OrdenProduccion[]> {
    return this.http.get<OrdenProduccion[]>(`${this.myAppUrl}${this.myApiUrl}/ordenes/`);
  }

  // GET: obtener una orden específica por su id
  getOrdenProduccion(id_orden: number): Observable<OrdenProduccion> {
    return this.http.get<OrdenProduccion>(`${this.myAppUrl}${this.myApiUrl}/ordenes/${id_orden}/`);
  }

  // POST: insertar una nueva orden de producción
  insertarOrdenProduccion(nuevaOrden: OrdenProduccion): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/ordenes/insertar/`, nuevaOrden);
  }

  // PUT: actualizar una orden de producción
  actualizarOrdenProduccion(id_orden: number, ordenEditada: OrdenProduccion): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/ordenes/actualizar/${id_orden}/`, ordenEditada);
  }

  // DELETE: eliminar una orden de producción
  eliminarOrdenProduccion(id_orden: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/ordenes/eliminar/${id_orden}/`);
  }
}
