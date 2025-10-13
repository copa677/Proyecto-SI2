// src/app/services_back/inventario.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment.development';
import { Inventario } from '../../interface/inventario';

@Injectable({
  providedIn: 'root'
})
export class InventarioService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;      // URL base del backend
    this.myApiUrl = 'api/inventario';          // Endpoint principal Django
  }

  // ===========================
  // 📦 INVENTARIO
  // ===========================

  // GET: listar todos los registros de inventario
  getInventario(): Observable<Inventario[]> {
    return this.http.get<Inventario[]>(`${this.myAppUrl}${this.myApiUrl}/inventario/`);
  }

  // GET: obtener un registro de inventario por ID
  getInventarioById(id_inventario: number): Observable<Inventario> {
    return this.http.get<Inventario>(`${this.myAppUrl}${this.myApiUrl}/inventario/${id_inventario}/`);
  }

  // POST: registrar nuevo inventario
  registrarInventario(nuevoInventario: Inventario): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/inventario/registrar/`, nuevoInventario);
  }

  // PUT: actualizar un inventario existente
  actualizarInventario(id_inventario: number, inventarioEditado: Inventario): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/inventario/actualizar/${id_inventario}/`, inventarioEditado);
  }

  // DELETE: eliminar un inventario
  eliminarInventario(id_inventario: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/inventario/eliminar/${id_inventario}/`);
  }
}
