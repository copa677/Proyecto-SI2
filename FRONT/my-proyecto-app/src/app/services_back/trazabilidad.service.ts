import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';
import { Trazabilidad } from '../../interface/trazabilidad';


@Injectable({
  providedIn: 'root'
})
export class TrazabilidadService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
  this.myAppUrl = environment.endpoint;
  this.myApiUrl = 'api/trazabilidad/trazabilidades/';
  }

  getTrazabilidades(): Observable<Trazabilidad[]> {
  return this.http.get<Trazabilidad[]>(`${this.myAppUrl}${this.myApiUrl}`);
  }

  getTrazabilidad(id: number): Observable<Trazabilidad> {
    return this.http.get<Trazabilidad>(`${this.myAppUrl}${this.myApiUrl}${id}/`);
  }

  insertarTrazabilidad(trazabilidad: Trazabilidad): Observable<Trazabilidad> {
    return this.http.post<Trazabilidad>(`${this.myAppUrl}${this.myApiUrl}`, trazabilidad);
  }

  actualizarTrazabilidad(id: number, trazabilidad: Trazabilidad): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}${id}/`, trazabilidad);
  }

  eliminarTrazabilidad(id: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}${id}/`);
  }
}
