import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class NotaSalidaService {
  private apiUrl = 'http://localhost:8000/api/notas_salida/';
  private detallesUrl = 'http://localhost:8000/api/detalles_salida/';

  constructor(private http: HttpClient) {}

  getNotasSalida(): Observable<any[]> {
    return this.http.get<any[]>(this.apiUrl);
  }

  getDetallesSalida(id_salida: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.detallesUrl}${id_salida}/`);
  }
}
