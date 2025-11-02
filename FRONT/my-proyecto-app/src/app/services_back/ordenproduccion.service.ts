import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

export interface OrdenProduccion {
  id_orden?: number;
  cod_orden: string;
  fecha_inicio: string;
  fecha_fin: string;
  fecha_entrega: string;
  estado: string;
  producto_modelo: string;
  color: string;
  talla: string;
  cantidad_total: number;
  id_personal: number;
}

export interface MateriaPrimaOrden {
  id_inventario: number;
  cantidad: number;
}

export interface CrearOrdenConMaterias {
  cod_orden: string;
  fecha_inicio: string;
  fecha_fin: string;
  fecha_entrega: string;
  producto_modelo: string;
  color: string;
  talla: string;
  cantidad_total: number;
  id_personal: number;
  materias_primas: MateriaPrimaOrden[];
}

@Injectable({ providedIn: 'root' })
export class OrdenProduccionService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/ordenproduccion/ordenes/';
  }

  getOrdenes(): Observable<OrdenProduccion[]> {
    return this.http.get<OrdenProduccion[]>(`${this.myAppUrl}${this.myApiUrl}`);
  }

  getOrden(id: number): Observable<OrdenProduccion> {
    return this.http.get<OrdenProduccion>(`${this.myAppUrl}${this.myApiUrl}${id}/`);
  }

  createOrden(orden: Partial<OrdenProduccion>): Observable<any> {
    return this.http.post(`${this.myAppUrl}${this.myApiUrl}insertar/`, orden);
  }

  // 🔹 Nuevo método: Crear orden con materias primas (genera nota de salida automáticamente)
  createOrdenConMaterias(orden: CrearOrdenConMaterias): Observable<any> {
    return this.http.post(`${this.myAppUrl}${this.myApiUrl}crear-con-materias/`, orden);
  }

  updateOrden(id: number, orden: Partial<OrdenProduccion>): Observable<any> {
    return this.http.put(`${this.myAppUrl}${this.myApiUrl}actualizar/${id}/`, orden);
  }

  deleteOrden(id: number): Observable<any> {
    return this.http.delete(`${this.myAppUrl}${this.myApiUrl}eliminar/${id}/`);
  }

  getTrazabilidad(id_orden: number): Observable<any> {
    return this.http.get(`${this.myAppUrl}${this.myApiUrl}${id_orden}/trazabilidad/`);
  }
}
