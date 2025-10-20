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

  obtenerPermisos(): Observable<any[]> {
    return this.http.get<any[]>(`${this.myAppUrl}${this.myApiUrl}/permisos-lista`);
  }

  obtenerPermisosDeUsuario(username: string): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/getpermisosUser/${username}`);
  }

  obtenerPermisosDeUsuarioVentana(username: string, ventana: string): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/getpermisosUser_Ventana/${username}/${ventana}`);
  }

  asignarPermiso(username: string, permiso: any): Observable<any> {
    // El objeto permiso debe tener los campos requeridos por el backend
    return this.http.post(`${this.myAppUrl}${this.myApiUrl}/permisos`, { name_user: username, ...permiso });
  }

  // El backend actual no tiene endpoint explícito para revocar, se puede implementar si es necesario
}
