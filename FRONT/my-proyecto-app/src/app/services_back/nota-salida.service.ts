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
    this.myAppUrl = environment.endpoint;       // Base del backend
    this.myApiUrl = 'api/notasalida';           // Prefijo definido en urls.py del proyecto
  }

  // ===========================
  // 🧾 NOTAS DE SALIDA
  // ===========================

  getNotasSalida(): Observable<NotaSalida[]> {
    return this.http.get<NotaSalida[]>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/`);
  }

  getNotaSalidaById(id_salida: number): Observable<NotaSalida> {
    return this.http.get<NotaSalida>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/${id_salida}/`);
  }

  registrarNotaSalida(id_usuario: number, nuevaNota: NotaSalida): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/registrar/${id_usuario}/`, nuevaNota);
  }

  actualizarNotaSalida(id_salida: number, notaEditada: NotaSalida): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/actualizar/${id_salida}/`, notaEditada);
  }

  eliminarNotaSalida(id_salida: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/notas_salida/eliminar/${id_salida}/`);
  }

  // ===========================
  // 📦 DETALLES DE SALIDA
  // ===========================

  getDetallesSalida(id_salida: number): Observable<DetalleNotaSalida[]> {
    return this.http.get<DetalleNotaSalida[]>(`${this.myAppUrl}${this.myApiUrl}/detalles_salida/${id_salida}/`);
  }

  getDetalleSalidaById(id_detalle: number): Observable<DetalleNotaSalida> {
    return this.http.get<DetalleNotaSalida>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/${id_detalle}/`);
  }

  registrarDetalleSalida(id_salida: number, nuevoDetalle: DetalleNotaSalida): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/registrar/${id_salida}/`, nuevoDetalle);
  }

  actualizarDetalleSalida(id_detalle: number, detalleEditado: DetalleNotaSalida): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/actualizar/${id_detalle}/`, detalleEditado);
  }

  eliminarDetalleSalida(id_detalle: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/detalle_salida/eliminar/${id_detalle}/`);
  }
}
