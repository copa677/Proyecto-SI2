import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

@Injectable({ providedIn: 'root' })
export class NotaSalidaService {
  private myAppUrl: string;
  private myApiUrl: string;
  private detallesApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/notasalida/notas_salida/';
    this.detallesApiUrl = 'api/notasalida/detalles_salida/';
  }

  getNotasSalida(): Observable<any[]> {
    return this.http.get<any[]>(`${this.myAppUrl}${this.myApiUrl}`);
  }

  getDetallesSalida(id_salida: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.myAppUrl}${this.detallesApiUrl}${id_salida}/`);
  }

  createNotaSalida(nota: any): Observable<any> {
    return this.http.post<any>(`${this.myAppUrl}${this.myApiUrl}crear/`, nota);
  }
}
