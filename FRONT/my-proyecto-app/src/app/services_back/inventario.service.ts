import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Inventario } from '../inventario.interface';
import { environment } from '../../environments/environment.development';

@Injectable({
  providedIn: 'root'
})
export class InventarioService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;        // Base URL del backend
    this.myApiUrl = 'api/inventario/inventario'; // Endpoint de la app Django
  }

  getInventarios(): Observable<Inventario[]> {
    return this.http.get<Inventario[]>(`${this.myAppUrl}${this.myApiUrl}/`).pipe(
      catchError(error => {
        console.error('Error al obtener inventarios:', error);
        throw error;
      })
    );
  }

  getInventario(id: number): Observable<Inventario> {
    return this.http.get<Inventario>(`${this.myAppUrl}${this.myApiUrl}/${id}/`).pipe(
      catchError(error => {
        console.error(`Error al obtener inventario con ID ${id}:`, error);
        throw error;
      })
    );
  }

  createInventario(inventario: Partial<Inventario>): Observable<Inventario> {
    return this.http.post<Inventario>(`${this.myAppUrl}${this.myApiUrl}/registrar/`, inventario).pipe(
      catchError(error => {
        console.error('Error al crear inventario:', error);
        throw error;
      })
    );
  }

  updateInventario(id: number, inventario: Partial<Inventario>): Observable<Inventario> {
    return this.http.put<Inventario>(`${this.myAppUrl}${this.myApiUrl}/actualizar/${id}/`, inventario).pipe(
      catchError(error => {
        console.error(`Error al actualizar inventario con ID ${id}:`, error);
        throw error;
      })
    );
  }

  deleteInventario(id: number): Observable<any> {
    return this.http.delete(`${this.myAppUrl}${this.myApiUrl}/eliminar/${id}/`).pipe(
      catchError(error => {
        console.error(`Error al eliminar inventario con ID ${id}:`, error);
        throw error;
      })
    );
  }

  // 📊 Obtener trazabilidad del lote
  getTrazabilidadPorLote(id_lote: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.myAppUrl}api/trazabilidad/trazabilidades/?id_lote=${id_lote}`).pipe(
      catchError(error => {
        console.error(`Error al obtener trazabilidad del lote ${id_lote}:`, error);
        throw error;
      })
    );
  }
}
