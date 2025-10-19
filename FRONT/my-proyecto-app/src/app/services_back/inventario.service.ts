import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Inventario } from '../inventario.interface';

@Injectable({
  providedIn: 'root'
})
export class InventarioService {
  private apiUrl = 'http://localhost:8000/api/inventario/inventario';

  constructor(private http: HttpClient) { }

  getInventarios(): Observable<Inventario[]> {
    return this.http.get<Inventario[]>(`${this.apiUrl}/`);
  }

  getInventario(id: number): Observable<Inventario> {
    return this.http.get<Inventario>(`${this.apiUrl}/${id}/`);
  }

  createInventario(inventario: Partial<Inventario>): Observable<Inventario> {
    return this.http.post<Inventario>(`${this.apiUrl}/registrar/`, inventario);
  }

  updateInventario(id: number, inventario: Partial<Inventario>): Observable<Inventario> {
    return this.http.put<Inventario>(`${this.apiUrl}/actualizar/${id}/`, inventario);
  }

  deleteInventario(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/eliminar/${id}/`);
  }

    // Nuevo método para obtener trazabilidad del lote
    getTrazabilidadPorLote(id_lote: number): Observable<any[]> {
      // Ajusta la URL según tu backend, aquí se asume que el endpoint acepta filtro por id_lote
      return this.http.get<any[]>(`http://localhost:8000/api/trazabilidad/trazabilidades/?id_lote=${id_lote}`);
    }
}
