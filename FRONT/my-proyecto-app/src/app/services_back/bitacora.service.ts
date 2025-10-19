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
  username: string = '';
  IP: string = "";
  fechaHora: string = this.getLocalDateTime();

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/bitacora';
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

  OptenerIP() {
    this.getUserIP().subscribe(
      response => {
        this.IP = response;
      },
      error => {
        console.log('Error al obtener la IP:', error);
      }
    );
  }

  // ⏰ Obtener la fecha y hora local del usuario en formato ISO (compatible con Django)
  getLocalDateTime(): string {
    const now = new Date();
    const offsetMs = now.getTimezoneOffset() * 60000;
    const localISOTime = new Date(now.getTime() - offsetMs).toISOString().slice(0, 19);
    return localISOTime;
  }

  // � Obtener el usuario desde el token JWT
  getUserFromToken(): void {
    const token = localStorage.getItem('token');
    if (!token) {
      console.warn('No se encontró el token en el localStorage.');
      this.username = ''; // limpiamos la variable por seguridad
      return;
    }

    const parts = token.split('.');
    if (parts.length !== 3) {
      console.error('El token no tiene el formato esperado.');
      this.username = '';
      return;
    }

    try {
      const payload = JSON.parse(this.b64urlDecode(parts[1]));
      // Guardamos directamente en la variable del servicio
      this.username = payload.name_user || payload.username || '';
      console.log('✅ Usuario obtenido del token:', this.username);
    } catch (error) {
      console.error('❌ Error al decodificar el token:', error);
      this.username = '';
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
  registrarAccion(accion: string, descripcion: string){
    this.getUserFromToken();
    this.OptenerIP();
    // Obtenemos la IP del usuario
    const bitacora: Bitacora = {
        username: this.username,
        ip: this.IP,
        fecha_hora: this.getLocalDateTime(),
        accion: accion,
        descripcion: descripcion
    };

    // Enviamos la bitácora al backend y ejecutamos el subscribe aquí mismo
    return this.registrarBitacora(bitacora).subscribe()
  }


}
