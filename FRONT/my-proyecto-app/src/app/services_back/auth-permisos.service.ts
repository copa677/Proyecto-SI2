import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { environment } from '../../environments/environment.development';

@Injectable({
  providedIn: 'root'
})
export class AuthPermisosService {
  private myAppUrl: string;
  private myApiUrl: string;
  private permisosCache: string[] = [];

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/usuario';
  }

  cargarPermisos(): Observable<string[]> {
    const usuario = JSON.parse(localStorage.getItem('usuario') || '{}');
    const idUsuario = usuario.id;

    if (!idUsuario) {
      return of([]);
    }

    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/permisos/${idUsuario}/`).pipe(
      map((response): string[] => {
  this.permisosCache = response?.permisos ?? [];
  return this.permisosCache;
      }),
      catchError(error => {
        console.error('Error al cargar permisos:', error);
        return of([]);
      })
    );
  }

  tienePermiso(nombrePermiso: string): Observable<boolean> {
    return of(this.permisosCache.includes(nombrePermiso));

    return this.cargarPermisos().pipe(
      map(permisos => permisos.includes(nombrePermiso))
    );
  }

  limpiarCache() {
  this.permisosCache = [];
  }
}
