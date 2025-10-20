// src/app/services_back/auth-permisos.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { environment } from '../../environments/environment.development';

@Injectable({
  providedIn: 'root'
})
export class AuthPermisosService {
  private myAppUrl: string;
  private myApiUrl: string;
  private permisosCache: string[] = [];

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;     // Base URL del backend
    this.myApiUrl = 'api/usuario';            // Endpoint de la app Django
  }

  // 📥 Cargar permisos del usuario logueado
  cargarPermisos(): Observable<string[]> {
    const usuario = JSON.parse(localStorage.getItem('usuario') || '{}');
    const idUsuario = usuario?.id;

    if (!idUsuario) {
      console.warn('No se encontró el ID del usuario en localStorage');
      return of([]);
    }

    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/permisos/${idUsuario}/`).pipe(
      map(response => {
        this.permisosCache = response?.permisos ?? [];
        return this.permisosCache;
      }),
      catchError(error => {
        console.error('Error al cargar permisos:', error);
        return of([]);
      })
    );
  }

  // 🔐 Verificar si el usuario tiene un permiso específico
  tienePermiso(nombrePermiso: string): Observable<boolean> {
    // Si ya hay permisos cargados en cache, usamos eso
    if (this.permisosCache.length > 0) {
      return of(this.permisosCache.includes(nombrePermiso));
    }

    // Si no hay cache, recargamos los permisos desde el backend
    return this.cargarPermisos().pipe(
      map(permisos => permisos.includes(nombrePermiso)),
      catchError(() => of(false))
    );
  }

  // 🧹 Limpiar el cache de permisos (por ejemplo, al cerrar sesión)
  limpiarCache(): void {
    this.permisosCache = [];
  }

  // 💡 Método auxiliar: Obtener ID del usuario actual desde localStorage
  getUserId(): number | null {
    const usuario = JSON.parse(localStorage.getItem('usuario') || '{}');
    return usuario?.id ?? null;
  }
}
