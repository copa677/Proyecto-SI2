import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Turno } from '../../interface/turno';
import { environment } from '../../environments/environment.development';

@Injectable({
  providedIn: 'root'
})
export class TurnosService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/turnos';
  }

  getTurnos(): Observable<Turno[]> {
    return this.http.get<Turno[]>(`${this.myAppUrl}${this.myApiUrl}/listar`);
  }

  getTurno(id: number): Observable<Turno> {
    return this.http.get<Turno>(`${this.myAppUrl}${this.myApiUrl}/${id}/`);
  }

  createTurno(turno: Partial<Turno>): Observable<Turno> {
    return this.http.post<Turno>(`${this.myAppUrl}${this.myApiUrl}/agregar`, turno);
  }

  updateTurno(id: number, turno: Partial<Turno>): Observable<Turno> {
    return this.http.put<Turno>(`${this.myAppUrl}${this.myApiUrl}/actualizar/${id}`, turno);
  }

  deleteTurno(id: number): Observable<any> {
    return this.http.delete(`${this.myAppUrl}${this.myApiUrl}/eliminar/${id}`);
  }
}
