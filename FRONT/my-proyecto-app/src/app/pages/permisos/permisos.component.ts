import { Component, OnInit } from '@angular/core';
import { PermisosService } from '../../services_back/permisos.service';

@Component({
  selector: 'app-permisos',
  templateUrl: './permisos.component.html',
  styleUrls: ['./permisos.component.css']
})
export class PermisosComponent implements OnInit {
  permisos: any[] = [];

  constructor(private permisosService: PermisosService) {}

  ngOnInit(): void {
    this.cargarPermisos();
  }

  cargarPermisos() {
    this.permisosService.obtenerPermisos().subscribe({
      next: (data: any) => {
        this.permisos = data;
      },
      error: (error: any) => {
        console.error('Error al cargar permisos:', error);
      }
    });
  }
}
