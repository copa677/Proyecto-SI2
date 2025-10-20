import { Directive, Input, TemplateRef, ViewContainerRef, OnInit } from '@angular/core';
import { PermissionService } from '../services_back/permission.service';
import { LoginService } from '../services_back/login.service';

/**
 * Directiva estructural para mostrar/ocultar elementos basándose en permisos de ventana
 * 
 * Uso:
 * <button *appCanDo="'editar'; ventana: 'Personal'">Editar</button>
 * <button *appCanDo="'insertar'; ventana: 'Inventario'">Crear Nuevo</button>
 * <button *appCanDo="'eliminar'; ventana: 'Usuarios'">Eliminar</button>
 */
@Directive({
  selector: '[appCanDo]'
})
export class CanDoDirective implements OnInit {
  @Input() appCanDo: 'insertar' | 'editar' | 'eliminar' | 'ver' = 'ver';
  @Input() appCanDoVentana: string = '';

  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
    private permissionService: PermissionService,
    private loginService: LoginService
  ) {}

  ngOnInit() {
    const username = this.loginService.getUsernameFromToken();
    
    if (!username || !this.appCanDoVentana) {
      // Si no hay username o ventana, ocultar el elemento
      this.viewContainer.clear();
      return;
    }

    // Verificar si el usuario puede realizar la acción
    this.permissionService.puedeRealizarAccion(username, this.appCanDoVentana, this.appCanDo)
      .subscribe({
        next: (puede) => {
          if (puede) {
            // Si tiene permiso, mostrar el elemento
            this.viewContainer.createEmbeddedView(this.templateRef);
          } else {
            // Si no tiene permiso, ocultar el elemento
            this.viewContainer.clear();
          }
        },
        error: (error) => {
          console.error('Error al verificar permiso:', error);
          // En caso de error, ocultar el elemento por seguridad
          this.viewContainer.clear();
        }
      });
  }
}
