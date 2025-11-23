import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

export interface PrecioProducto {
  id_precio: number;
  decripcion: string;
  material: string;
  talla: string;
  precio_base: number;
  activo: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class PrecioService {
  private baseUrl = `${environment.endpoint}api/precios`;

  constructor(private http: HttpClient) { }

  /**
   * Obtiene todos los precios activos
   */

  // Lista precios activos
  listarPrecios(): Observable<PrecioProducto[]> {
    return this.http.get<PrecioProducto[]>(`${this.baseUrl}/listar/`);
  }

  // Lista todos los precios (activos e inactivos)
  listarTodosPrecios(): Observable<PrecioProducto[]> {
    return this.http.get<PrecioProducto[]>(`${this.baseUrl}/precios/all/`);
  }

  /**
   * Busca precios filtrados
   */
  // Buscar precios (por query string)
  buscarPrecios(query: string): Observable<PrecioProducto[]> {
    return this.http.get<PrecioProducto[]>(`${this.baseUrl}/precios/search/?q=${encodeURIComponent(query)}`);
  }

  // Obtener detalle de un precio por ID
  obtenerPrecio(id: number): Observable<PrecioProducto> {
    return this.http.get<PrecioProducto>(`${this.baseUrl}/precios/${id}/`);
  }

  // Crear un nuevo precio
  crearPrecio(precio: Partial<PrecioProducto>): Observable<PrecioProducto> {
    return this.http.post<PrecioProducto>(`${this.baseUrl}/precios/create/`, precio);
  }

  // Actualizar un precio existente
  actualizarPrecio(id: number, precio: Partial<PrecioProducto>): Observable<PrecioProducto> {
    return this.http.put<PrecioProducto>(`${this.baseUrl}/precios/update/${id}/`, precio);
  }

  // Eliminar (desactivar) un precio
  eliminarPrecio(id: number): Observable<any> {
    return this.http.delete<any>(`${this.baseUrl}/precios/delete/${id}/`);
  }

  // Activar un precio previamente desactivado
  activarPrecio(id: number): Observable<PrecioProducto> {
    return this.http.put<PrecioProducto>(`${this.baseUrl}/precios/activate/${id}/`, {});
  }
}
