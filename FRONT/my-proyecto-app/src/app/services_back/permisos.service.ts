import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class PermisosService {
  private apiUrl = 'http://localhost:8000/api/usuario';

  constructor(private http: HttpClient) {}

  obtenerPermisos(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/permisos-lista`);
  }

  obtenerPermisosDeUsuario(username: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getpermisosUser/${username}`);
  }

  obtenerPermisosDeUsuarioVentana(username: string, ventana: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/getpermisosUser_Ventana/${username}/${ventana}`);
  }

  asignarPermiso(username: string, permiso: any): Observable<any> {
    // El objeto permiso debe tener los campos requeridos por el backend
    return this.http.post(`${this.apiUrl}/permisos`, { name_user: username, ...permiso });
  }

  // El backend actual no tiene endpoint explícito para revocar, se puede implementar si es necesario
}
