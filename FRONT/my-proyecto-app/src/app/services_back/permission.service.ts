import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { environment } from '../../environments/environment.development';
import {jwtDecode} from 'jwt-decode';

// Matriz de permisos por ROL (predeterminados del sistema)
const ROLE_PERMISSIONS = {
  'admin': ['all'], // Administrador tiene todos los permisos
  'Administrador': ['all'], // Compatibilidad con roles del backend
  'empleado': [
    'ver_inventario',
    'ver_lotes',
    'ver_ordenes',
    'agregar_ordenes',
    'editar_ordenes',
    'ver_calidad',
    'agregar_calidad',
    'ver_trazabilidad',
    'ver_notificaciones'
  ],
  'Supervisor': [
    'gestionar_personal',
    'ver_inventario',
    'ver_lotes',
    'ver_ordenes',
    'agregar_ordenes',
    'editar_ordenes',
    'ver_calidad',
    'agregar_calidad',
    'ver_trazabilidad',
    'ver_notificaciones',
    'asignar_roles',
    'ver_reportes'
  ],
  'Operario': [
    'ver_inventario',
    'ver_lotes',
    'ver_ordenes',
    'agregar_ordenes',
    'ver_calidad',
    'agregar_calidad',
    'ver_trazabilidad',
    'ver_notificaciones'
  ]
};

// Mapeo de páginas a permisos
const PAGE_PERMISSIONS: { [key: string]: string } = {
  'bitacora': 'ver_bitacora',
  'permisos': 'gestionar_permisos',
  'asignar-permisos': 'asignar_permisos',
  'usuarios': 'gestionar_usuarios',
  'clientes': 'gestionar_clientes',
  'personal': 'gestionar_personal',
  'asistencia': 'gestionar_asistencia',
  'turnos': 'gestionar_turnos',
  'inventario': 'ver_inventario',
  'lotes': 'ver_lotes',
  'ordenproduccion': 'ver_ordenes',
  'trazabilidad': 'ver_trazabilidad',
  'control-calidad': 'ver_calidad',
  'nota-salida': 'gestionar_notas_salida',
  'reporte-inventario': 'ver_reportes',
  'reporte-produccion': 'ver_reportes',
  'reporte-ventas': 'ver_reportes'
};

@Injectable({
  providedIn: 'root'
})
export class PermissionService {
  private myAppUrl: string;
  private userRole$ = new BehaviorSubject<string | null>(null);
  private permisosVentana$ = new BehaviorSubject<any>({});
  private permisosBackend$ = new BehaviorSubject<string[]>([]);

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.loadUserRoleFromToken();
  }

  /**
   * Carga el rol del usuario desde el token JWT almacenado
   */
  private loadUserRoleFromToken() {
    const token = localStorage.getItem('token');
    if (token) {
      try {
        const decoded: any = jwtDecode(token);
        this.userRole$.next(decoded.tipo_usuario || null);
      } catch (error) {
        console.error('Error al decodificar token:', error);
        this.userRole$.next(null);
      }
    }
  }

  /**
   * Establece el rol del usuario manualmente
   */
  setUserRole(role: string) {
    this.userRole$.next(role);
  }

  /**
   * Obtiene el rol actual del usuario
   */
  getUserRole(): string | null {
    return this.userRole$.value;
  }

  /**
   * Verifica si el usuario tiene un permiso basado en ROL (sistema predeterminado)
   */
  hasRolePermission(permission: string): boolean {
    const role = localStorage.getItem('userRole') || this.userRole$.value;
    if (!role) return false;

    // Administrador tiene todos los permisos
    if (role === 'Administrador' || role === 'admin') return true;

    const rolePerms = ROLE_PERMISSIONS[role as keyof typeof ROLE_PERMISSIONS] || [];
    return rolePerms.includes('all') || rolePerms.includes(permission);
  }

  /**
   * Alias de hasRolePermission para compatibilidad con componentes existentes
   */
  hasPermission(permission: string): boolean {
    return this.hasRolePermission(permission);
  }

  /**
   * Obtiene el permiso requerido para una página específica
   */
  getPagePermission(pageName: string): string | null {
    return PAGE_PERMISSIONS[pageName] || null;
  }

  /**
   * Verifica si el usuario puede acceder a una página específica
   */
  canAccessPage(pageName: string): boolean {
    const permission = this.getPagePermission(pageName);
    if (!permission) return true; // Si no hay permiso definido, permitir acceso

    return this.hasPermission(permission);
  }

  /**
   * Obtiene los permisos de un usuario para una ventana específica desde la BD
   */
  obtenerPermisosVentana(username: string, ventana: string): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}api/usuario/getpermisosUser_Ventana/${username}/${ventana}`).pipe(
      map(permisos => {
        // Guardar en cache
        const key = `${username}_${ventana}`;
        const current = this.permisosVentana$.value;
        this.permisosVentana$.next({ ...current, [key]: permisos });
        return permisos;
      }),
      catchError(error => {
        console.error('Error al obtener permisos de ventana:', error);
        return of({ insertar: false, editar: false, eliminar: false, ver: false });
      })
    );
  }

  /**
   * Verifica si el usuario puede realizar una acción en una ventana específica
   */
  puedeRealizarAccion(username: string, ventana: string, accion: 'insertar' | 'editar' | 'eliminar' | 'ver'): Observable<boolean> {
    // Si es admin o Administrador, puede todo
    const role = localStorage.getItem('userRole') || this.getUserRole();
    if (role === 'admin' || role === 'Administrador') {
      return of(true);
    }

    const key = `${username}_${ventana}`;
    const permisos = this.permisosVentana$.value[key];

    if (permisos) {
      return of(permisos[accion] === true);
    }

    // Si no está en cache, cargar desde el servidor
    return this.obtenerPermisosVentana(username, ventana).pipe(
      map(p => p[accion] === true)
    );
  }

  /**
   * Asigna permisos a un usuario para una ventana específica
   */
  asignarPermisos(username: string, ventana: string, permisos: any): Observable<any> {
    return this.http.post(`${this.myAppUrl}api/usuario/permisos`, {
      name_user: username,
      ventana: ventana,
      ...permisos
    });
  }

  /**
   * Limpia el cache de permisos (útil al cerrar sesión)
   */
  limpiarCache() {
    this.userRole$.next(null);
    this.permisosVentana$.next({});
    this.permisosBackend$.next([]);
  }

  /**
   * Carga los permisos del usuario desde el backend (lista de strings con nombres de permisos)
   */
  cargarPermisosBackend(idUsuario: number): Observable<string[]> {
    return this.http.get<any>(`${this.myAppUrl}api/usuario/permisos/${idUsuario}/`).pipe(
      map((response): string[] => {
        const permisos = response?.permisos ?? [];
        this.permisosBackend$.next(permisos);
        return permisos;
      }),
      catchError(error => {
        console.error('Error al cargar permisos del backend:', error);
        return of([]);
      })
    );
  }

  /**
   * Verifica si el usuario tiene un permiso específico por nombre (backend)
   * Compatible con AuthPermisosService.tienePermiso()
   */
  tienePermiso(nombrePermiso: string): Observable<boolean> {
    // Si es admin, tiene todos los permisos
    if (this.getUserRole() === 'admin' || this.getUserRole() === 'Administrador') {
      return of(true);
    }

    // Si ya tenemos permisos en cache, verificar
    const permisos = this.permisosBackend$.value;
    if (permisos.length > 0) {
      return of(permisos.includes(nombrePermiso));
    }

    // Si no hay cache, cargar desde el servidor
    const usuario = JSON.parse(localStorage.getItem('usuario') || '{}');
    const idUsuario = usuario.id;

    if (!idUsuario) {
      return of(false);
    }

    return this.cargarPermisosBackend(idUsuario).pipe(
      map(permisos => permisos.includes(nombrePermiso))
    );
  }
}
