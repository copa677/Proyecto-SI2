// src/app/services_back/bitacora.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { environment } from '../../environments/environment.development';
import { Bitacora } from '../../interface/bitacora';

@Injectable({
  providedIn: 'root'
})
export class BitacoraService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;  // URL base del backend
    this.myApiUrl = 'api/bitacora';        // Endpoint de la app Django
  }

  // 📋 Obtener todas las bitácoras
  getBitacoras(): Observable<Bitacora[]> {
    return this.http.get<Bitacora[]>(`${this.myAppUrl}${this.myApiUrl}/listar`);
  }

  // 📝 Registrar una nueva bitácora
  registrarBitacora(newBitacora: Bitacora): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/registrar`, newBitacora);
  }

  // 🌐 Obtener la IP pública del usuario
  getUserIP(): Observable<string> {
    return this.http
      .get<{ ip: string }>('https://api.ipify.org?format=json')
      .pipe(map(response => response.ip));
  }

  // ⏰ Obtener la fecha y hora local del usuario en formato ISO (compatible con Django)
  getLocalDateTime(): string {
    const now = new Date();
    const offsetMs = now.getTimezoneOffset() * 60000;
    const localISOTime = new Date(now.getTime() - offsetMs).toISOString().slice(0, 19);
    return localISOTime;
  }

  // 💡 Método auxiliar: Crear objeto Bitacora básico automáticamente
  generarBitacora(username: string, accion: string, descripcion: string): Observable<Bitacora> {
    return this.getUserIP().pipe(
      map(ip => ({
        username: username,
        ip: ip,
        fecha_hora: this.getLocalDateTime(),
        accion: accion,
        descripcion: descripcion
      }))
    );
  }
}
