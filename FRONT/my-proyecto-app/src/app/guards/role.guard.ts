// src/app/guards/role.guard.ts
import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { AuthService } from '../services/auth.service';
import { PermissionService } from '../services_back/permission.service';

@Injectable({
  providedIn: 'root'
})
export class RoleGuard implements CanActivate {

  constructor(
    private authService: AuthService,
    private permissionService: PermissionService,
    private router: Router
  ) {}

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): boolean | Observable<boolean> {
    // Verificar si el usuario está autenticado
    if (!this.authService.isAuthenticated()) {
      this.router.navigate(['/login']);
      return false;
    }

    // Obtener los roles permitidos y el permiso específico de la configuración de la ruta
    const allowedRoles = route.data['roles'] as Array<string>;
    const requiredPermission = route.data['permission'] as string;
    const ventana = this.getVentanaName(route.routeConfig?.path || '');
    
    // Si es administrador, siempre tiene acceso
    if (this.authService.isAdmin()) {
      return true;
    }

    // Verificar permisos en la base de datos si hay una ventana específica
    if (ventana) {
      const username = this.authService.getUserName();
      return this.permissionService.puedeRealizarAccion(username, ventana, 'ver').pipe(
        map(tienePermiso => {
          if (tienePermiso) {
            return true;
          }
          
          // Si no tiene permiso en BD, verificar por rol
          if (requiredPermission && this.permissionService.hasPermission(requiredPermission)) {
            return true;
          }

          if (allowedRoles && allowedRoles.length > 0 && this.authService.hasAnyRole(allowedRoles)) {
            return true;
          }

          alert('No tienes permisos para acceder a esta página');
          this.router.navigate(['/menu/dashboard']);
          return false;
        })
      );
    }

    // Verificar por permiso específico primero (más granular)
    if (requiredPermission) {
      if (this.permissionService.hasPermission(requiredPermission)) {
        return true;
      }
    }

    // Verificar por roles si están especificados
    if (allowedRoles && allowedRoles.length > 0) {
      if (this.authService.hasAnyRole(allowedRoles)) {
        return true;
      }
    }

    // Si no hay roles ni permisos especificados, permitir el acceso
    if ((!allowedRoles || allowedRoles.length === 0) && !requiredPermission) {
      return true;
    }

    // Si no tiene permiso, redirigir a una página de acceso denegado o al dashboard
    alert('No tienes permisos para acceder a esta página');
    this.router.navigate(['/menu/dashboard']);
    return false;
  }

  /**
   * Convierte el path de la ruta al nombre de ventana usado en la BD
   */
  private getVentanaName(path: string): string {
    const ventanaMap: { [key: string]: string } = {
      'bitacora': 'Bitacora',
      'usuarios': 'Usuarios',
      'clientes': 'Clientes',
      'personal': 'Personal',
      'asistencia': 'Asistencia',
      'turnos': 'Turnos',
      'inventario': 'Inventario',
      'lotes': 'Lotes',
      'ordenproduccion': 'OrdenProduccion',
      'trazabilidad': 'Trazabilidad',
      'control-calidad': 'ControlCalidad',
      'nota-salida': 'NotaSalida',
      'permisos': 'Permisos',
      'asignar-permisos': 'AsignarPermisos'
    };
    return ventanaMap[path] || '';
  }
}
