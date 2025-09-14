
// src/app/services/turnos.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment.development';
import { Turno } from '../../interface/turno';
import { asistencia } from '../../interface/asistencia';

@Injectable({
  providedIn: 'root'
})
export class TurnosService {
  private myAppUrl: string;
  private myApiUrl: string;
  private myApiUrl2: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;         
    this.myApiUrl = 'api/turnos';   
    this.myApiUrl2 = 'api/asistencia';             
  }

  //SERVICES PARA TURNOS
  // GET lista de turnos
  getTurnos(): Observable<Turno[]> {
    return this.http.get<Turno[]>(`${this.myAppUrl}${this.myApiUrl}/listar`);
  }

  // POST registrar turno
  registrar_Turno(newTurno: Turno): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/registrar`, newTurno);
  }

  // POST actualizar turno
  desactivar_turno(id: number): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/desactivar/${id}`, {});
  }
  //SERVICES PARA ASISTENCIA
  // GET lista de asistencias
  getAsistencias(): Observable<asistencia[]> {
    return this.http.get<asistencia[]>(`${this.myAppUrl}${this.myApiUrl2}/listar`);
  }

  // POST registrar asistencia
  registrar_Asistencia(newAsistencia: asistencia): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl2}/registrar`, newAsistencia);
  }

}
