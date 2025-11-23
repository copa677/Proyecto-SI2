import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

@Injectable({
  providedIn: 'root'
})
export class BrService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/br';
  }

  /**
   * 📦 Generar respaldo de la base de datos.
   * Devuelve un blob descargable (.dump)
   */
  generarBackup(): Observable<Blob> {
    return this.http.get(`${this.myAppUrl}${this.myApiUrl}/backup/`, { responseType: 'blob' });
  }

  /**
   * 🔄 Restaurar base de datos desde un archivo .dump
   * Se envía el archivo seleccionado por el usuario.
   */
  restaurarBackup(archivo: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', archivo);
    return this.http.post(`${this.myAppUrl}${this.myApiUrl}/restore/`, formData);
  }

  /**
   * 📅 Programar backup (fecha específica o intervalo)
   */
  programarBackup(tipo: string, fechaHora?: string, intervaloHoras?: number): Observable<any> {
    const body: any = { tipo };
    if (tipo === 'fecha' && fechaHora) {
      body.fecha_programada = fechaHora;
    } else if (tipo === 'intervalo' && intervaloHoras) {
      body.intervalo_horas = intervaloHoras;
    }
    return this.http.post(`${this.myAppUrl}${this.myApiUrl}/programar/`, body);
  }
}
