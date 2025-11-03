// src/app/guards/role.guard.ts
import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable({
  providedIn: 'root'
})
export class RoleGuard implements CanActivate {

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  canActivate(
    route: ActivatedRouteSnapshot,
    state: RouterStateSnapshot
  ): boolean {
    // Verificar si el usuario está autenticado
    if (!this.authService.isAuthenticated()) {
      this.router.navigate(['/login']);
      return false;
    }

    // Obtener los roles permitidos de la configuración de la ruta
    const allowedRoles = route.data['roles'] as Array<string>;
    
    // Si no hay roles especificados, permitir el acceso
    if (!allowedRoles || allowedRoles.length === 0) {
      return true;
    }

    // Verificar si el usuario tiene alguno de los roles permitidos
    if (this.authService.hasAnyRole(allowedRoles)) {
      return true;
    }

    // Si no tiene permiso, redirigir a una página de acceso denegado o al inicio
    alert('No tienes permisos para acceder a esta página');
    this.router.navigate(['/inicio']);
    return false;
  }
}
