import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class AuthPermisosService {
  private apiUrl = 'http://localhost:8000/api/usuario';
  private permisosCache: string[] = [];

  constructor(private http: HttpClient) {}

  cargarPermisos(): Observable<string[]> {
    const usuario = JSON.parse(localStorage.getItem('usuario') || '{}');
    const idUsuario = usuario.id;

    if (!idUsuario) {
      return of([]);
    }

    return this.http.get<any>(`${this.apiUrl}/permisos/${idUsuario}/`).pipe(
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
