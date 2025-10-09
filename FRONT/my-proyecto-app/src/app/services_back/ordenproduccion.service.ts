import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface OrdenProduccion {
  id: number;
  codigo_orden: string;
  fecha_creacion: string;
  estado: string;
  cantidad: number;
}

@Injectable({ providedIn: 'root' })
export class OrdenProduccionService {
  private apiUrl = 'http://localhost:8000/api/ordenproduccion/';

  constructor(private http: HttpClient) {}

  getOrdenes(): Observable<OrdenProduccion[]> {
    return this.http.get<OrdenProduccion[]>(this.apiUrl);
  }

  createOrden(orden: Partial<OrdenProduccion>): Observable<any> {
    return this.http.post(this.apiUrl, orden);
  }

  updateOrden(id: number, orden: Partial<OrdenProduccion>): Observable<any> {
    return this.http.put(this.apiUrl + id + '/', orden);
  }

  deleteOrden(id: number): Observable<any> {
    return this.http.delete(this.apiUrl + id + '/');
  }
}
