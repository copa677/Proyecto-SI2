import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Turno } from '../../interface/turno';

@Injectable({
  providedIn: 'root'
})
export class TurnosService {
  private apiUrl = 'http://localhost:8000/api/turnos';

  constructor(private http: HttpClient) { }

  getTurnos(): Observable<Turno[]> {
    return this.http.get<Turno[]>(`${this.apiUrl}/listar`);
  }

  getTurno(id: number): Observable<Turno> {
    return this.http.get<Turno>(`${this.apiUrl}/${id}/`);
  }

  createTurno(turno: Partial<Turno>): Observable<Turno> {
    return this.http.post<Turno>(`${this.apiUrl}/crear_turno/`, turno);
  }

  updateTurno(id: number, turno: Partial<Turno>): Observable<Turno> {
    return this.http.put<Turno>(`${this.apiUrl}/actualizar_turno/${id}/`, turno);
  }

  deleteTurno(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/eliminar_turno/${id}/`);
  }
}
