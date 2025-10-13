// src/app/services_back/bitacora.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, forkJoin } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';

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

  // � Obtener el usuario desde el token JWT
  getUserFromToken(): string | null {
    const token = localStorage.getItem('token');
    if (!token) return null;

    const parts = token.split('.');
    if (parts.length !== 3) return null;

    try {
      const payload = JSON.parse(this.b64urlDecode(parts[1]));
      return payload.name_user || payload.username || null;
    } catch {
      return null;
    }
  }

  // Decodifica Base64URL (JWT) de forma segura
  private b64urlDecode(input: string): string {
    input = input.replace(/-/g, '+').replace(/_/g, '/');
    const pad = input.length % 4;
    if (pad) input += '='.repeat(4 - pad);
    return atob(input);
  }

  // 💡 Método auxiliar: Registrar bitácora automáticamente (obtiene usuario del token y IP automáticamente)
  registrarAccion(accion: string, descripcion: string): Observable<void> {
    const username = this.getUserFromToken();
    if (!username) {
      console.error('No se pudo obtener el usuario del token');
      return new Observable(observer => {
        observer.error('Usuario no autenticado');
      });
    }

    return this.getUserIP().pipe(
      switchMap(ip => {
        const bitacora: Bitacora = {
          username: username,
          ip: ip,
          fecha_hora: this.getLocalDateTime(),
          accion: accion,
          descripcion: descripcion
        };
        return this.registrarBitacora(bitacora);
      })
    );
  }

  // 💡 Método auxiliar alternativo: Crear objeto Bitacora básico automáticamente
  generarBitacora(accion: string, descripcion: string): Observable<Bitacora> {
    const username = this.getUserFromToken() || 'Usuario desconocido';
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
