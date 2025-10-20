import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

export interface OrdenProduccion {
  id: number;
  codigo_orden: string;
  fecha_creacion: string;
  estado: string;
  cantidad: number;
}

@Injectable({ providedIn: 'root' })
export class OrdenProduccionService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/ordenproduccion/';
  }

  getOrdenes(): Observable<OrdenProduccion[]> {
    return this.http.get<OrdenProduccion[]>(`${this.myAppUrl}${this.myApiUrl}`);
  }

  createOrden(orden: Partial<OrdenProduccion>): Observable<any> {
    return this.http.post(`${this.myAppUrl}${this.myApiUrl}`, orden);
  }

  updateOrden(id: number, orden: Partial<OrdenProduccion>): Observable<any> {
    return this.http.put(`${this.myAppUrl}${this.myApiUrl}${id}/`, orden);
  }

  deleteOrden(id: number): Observable<any> {
    return this.http.delete(`${this.myAppUrl}${this.myApiUrl}${id}/`);
  }
}
