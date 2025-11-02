import { Directive, Input, TemplateRef, ViewContainerRef, OnInit } from '@angular/core';
import { PermissionService } from '../services_back/permission.service';

@Directive({
  selector: '[appPermisoAccion]'
})
export class PermisoAccionDirective implements OnInit {
  @Input() appPermisoAccion: string = '';

  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
    private permissionService: PermissionService
  ) {}

  ngOnInit() {
    this.permissionService.tienePermiso(this.appPermisoAccion).subscribe(tienePermiso => {
      if (tienePermiso) {
        this.viewContainer.createEmbeddedView(this.templateRef);
      } else {
        this.viewContainer.clear();
      }
    });
  }
}
