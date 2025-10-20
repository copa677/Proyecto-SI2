import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import { PermissionService } from '../services_back/permission.service';
import { LoginService } from '../services_back/login.service';

/**
 * Guard para proteger rutas basándose en permisos de ventana
 * Uso en routing: canActivate: [PermissionGuard], data: { ventana: 'Bitacora', accion: 'ver' }
 */
@Injectable({
  providedIn: 'root'
})
export class PermissionGuard implements CanActivate {

  constructor(
    private permissionService: PermissionService,
    private loginService: LoginService,
    private router: Router
  ) {}

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): Observable<boolean> | Promise<boolean> | boolean {
    
    const ventana = route.data['ventana'];
    const accion = route.data['accion'] || 'ver';
    
    // Si no se especifica ventana, permitir acceso (por defecto)
    if (!ventana) {
      return true;
    }

    // Obtener username del token
    const username = this.loginService.getUsernameFromToken();
    if (!username) {
      console.warn('No se pudo obtener username del token');
      this.router.navigate(['/notes']);
      return false;
    }

    // Verificar si el usuario tiene el permiso
    return this.permissionService.puedeRealizarAccion(username, ventana, accion).pipe(
      map(tienePermiso => {
        if (!tienePermiso) {
          console.warn(`Acceso denegado: ${username} no tiene permiso para ${accion} en ${ventana}`);
          this.router.navigate(['/menu/dashboard'], { 
            queryParams: { error: 'acceso_denegado', ventana: ventana } 
          });
          return false;
        }
        return true;
      }),
      catchError(error => {
        console.error('Error al verificar permisos:', error);
        this.router.navigate(['/menu/dashboard']);
        return of(false);
      })
    );
  }
}
