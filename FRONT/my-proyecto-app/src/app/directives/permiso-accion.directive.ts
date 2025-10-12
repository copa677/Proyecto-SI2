import { Directive, Input, TemplateRef, ViewContainerRef, OnInit } from '@angular/core';
import { AuthPermisosService } from '../services_back/auth-permisos.service';

@Directive({
  selector: '[appPermisoAccion]'
})
export class PermisoAccionDirective implements OnInit {
  @Input() appPermisoAccion: string = '';

  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
    private authPermisosService: AuthPermisosService
  ) {}

  ngOnInit() {
    this.authPermisosService.tienePermiso(this.appPermisoAccion).subscribe(tienePermiso => {
      if (tienePermiso) {
        this.viewContainer.createEmbeddedView(this.templateRef);
      } else {
        this.viewContainer.clear();
      }
    });
  }
}
