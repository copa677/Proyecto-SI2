import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment.development';
import { Trazabilidad } from '../../interface/trazabilidad';
<<<<<<< Updated upstream
=======


>>>>>>> Stashed changes

@Injectable({
  providedIn: 'root'
})
export class TrazabilidadService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;        // Base URL del backend
    this.myApiUrl = 'api/trazabilidad';          // Endpoint Django principal
  }

  // ===========================
  // 🔍 TRAZABILIDAD
  // ===========================

  // GET: listar todas las trazabilidades
  getTrazabilidades(): Observable<Trazabilidad[]> {
    return this.http.get<Trazabilidad[]>(`${this.myAppUrl}${this.myApiUrl}/trazabilidades/`);
  }

  // GET: obtener una trazabilidad por id
  getTrazabilidad(id_trazabilidad: number): Observable<Trazabilidad> {
    return this.http.get<Trazabilidad>(`${this.myAppUrl}${this.myApiUrl}/trazabilidades/${id_trazabilidad}/`);
  }

  // POST: insertar una nueva trazabilidad
  insertarTrazabilidad(nuevaTrazabilidad: Trazabilidad): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/trazabilidades/insertar/`, nuevaTrazabilidad);
  }

  // PUT: actualizar trazabilidad existente
  actualizarTrazabilidad(id_trazabilidad: number, trazabilidadEditada: Trazabilidad): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/trazabilidades/actualizar/${id_trazabilidad}/`, trazabilidadEditada);
  }

  // DELETE: eliminar una trazabilidad
  eliminarTrazabilidad(id_trazabilidad: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/trazabilidades/eliminar/${id_trazabilidad}/`);
  }
}
