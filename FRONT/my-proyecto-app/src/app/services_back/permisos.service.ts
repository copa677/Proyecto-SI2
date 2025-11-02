import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

@Injectable({
  providedIn: 'root'
})
export class PermisosService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/usuario';
  }

  /**
   * Obtiene la lista de permisos disponibles en el sistema
   */
  obtenerPermisos(): Observable<any[]> {
    return this.http.get<any[]>(`${this.myAppUrl}${this.myApiUrl}/permisos-lista`);
  }

  /**
   * Obtiene todos los permisos de un usuario
   */
  obtenerPermisosDeUsuario(username: string): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/getpermisosUser/${username}`);
  }

  /**
   * Obtiene los permisos de un usuario para una ventana específica
   */
  obtenerPermisosDeUsuarioVentana(username: string, ventana: string): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/getpermisosUser_Ventana/${username}/${ventana}`);
  }

  /**
   * Asigna permisos a un usuario para una ventana específica
   */
  asignarPermiso(username: string, permiso: any): Observable<any> {
    return this.http.post(`${this.myAppUrl}${this.myApiUrl}/permisos`, { 
      name_user: username, 
      ...permiso 
    });
  }
}
