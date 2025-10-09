import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment.development';
import { ControlCalidad } from '../../interface/controlCalidad';

@Injectable({
  providedIn: 'root'
})
export class ControlCalidadService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;          // Base URL del backend
    this.myApiUrl = 'api/controlcalidad';          // Endpoint Django principal
  }

  // ===========================
  // 🔍 CONTROL DE CALIDAD
  // ===========================

  // GET: listar todos los controles de calidad
  getControles(): Observable<ControlCalidad[]> {
    return this.http.get<ControlCalidad[]>(`${this.myAppUrl}${this.myApiUrl}/controles/`);
  }

  // GET: obtener un control específico por id
  getControl(id_control: number): Observable<ControlCalidad> {
    return this.http.get<ControlCalidad>(`${this.myAppUrl}${this.myApiUrl}/controles/${id_control}/`);
  }

  // POST: insertar nuevo control de calidad
  insertarControl(nuevoControl: ControlCalidad): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/controles/insertar/`, nuevoControl);
  }

  // PUT: actualizar un control de calidad existente
  actualizarControl(id_control: number, controlEditado: ControlCalidad): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/controles/actualizar/${id_control}/`, controlEditado);
  }

  // DELETE: eliminar un control de calidad
  eliminarControl(id_control: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/controles/eliminar/${id_control}/`);
  }
}
