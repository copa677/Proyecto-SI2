// src/app/services_back/nota-salida.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment.development';
import { NotaSalida } from '../../interface/notaSalida';
import { DetalleNotaSalida } from '../../interface/detalleNotaSalida';

@Injectable({
  providedIn: 'root'
})
export class NotaSalidaService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;        // URL base del backend
    this.myApiUrl = 'api';                       // Base general para rutas Django
  }

  // ======================================
  // 🧾 NOTAS DE SALIDA
  // ======================================

  // GET: listar todas las notas de salida
  getNotasSalida(): Observable<NotaSalida[]> {
    return this.http.get<NotaSalida[]>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/`);
  }

  // GET: obtener una nota de salida específica por id
  getNotaSalidaById(id_salida: number): Observable<NotaSalida> {
    return this.http.get<NotaSalida>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/${id_salida}/`);
  }

  // POST: registrar una nueva nota de salida
  registrarNotaSalida(id_usuario: number, nuevaNota: NotaSalida): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/registrar/${id_usuario}/`, nuevaNota);
  }

  // PUT: actualizar una nota de salida existente
  actualizarNotaSalida(id_salida: number, notaEditada: NotaSalida): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/actualizar/${id_salida}/`, notaEditada);
  }

  // DELETE: eliminar una nota de salida
  eliminarNotaSalida(id_salida: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/eliminar/${id_salida}/`);
  }


  // ======================================
  // 📦 DETALLES DE NOTA DE SALIDA
  // ======================================

  // GET: listar todos los detalles de una nota de salida específica
  getDetallesSalida(id_salida: number): Observable<DetalleNotaSalida[]> {
    return this.http.get<DetalleNotaSalida[]>(`${this.myAppUrl}${this.myApiUrl}/detalles_salida/${id_salida}/`);
  }

  // GET: obtener un detalle específico por su id
  getDetalleSalidaById(id_detalle: number): Observable<DetalleNotaSalida> {
    return this.http.get<DetalleNotaSalida>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/${id_detalle}/`);
  }

  // POST: registrar un nuevo detalle de nota de salida
  registrarDetalleSalida(id_salida: number, nuevoDetalle: DetalleNotaSalida): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/registrar/${id_salida}/`, nuevoDetalle);
  }

  // PUT: actualizar un detalle existente
  actualizarDetalleSalida(id_detalle: number, detalleEditado: DetalleNotaSalida): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/actualizar/${id_detalle}/`, detalleEditado);
  }

  // DELETE: eliminar un detalle de nota de salida
  eliminarDetalleSalida(id_detalle: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/eliminar/${id_detalle}/`);
  }
}
