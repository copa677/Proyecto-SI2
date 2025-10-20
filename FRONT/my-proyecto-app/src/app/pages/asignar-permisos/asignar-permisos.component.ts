import { Component, OnInit } from '@angular/core';
import { PermisosService } from '../../services_back/permisos.service';
import { HttpClient } from '@angular/common/http';
import { LoginService } from '../../services_back/login.service';
 @Component({
  selector: 'app-asignar-permisos',
  templateUrl: './asignar-permisos.component.html',
  styleUrls: ['./asignar-permisos.component.css']
})
export class AsignarPermisosComponent implements OnInit {
  usuarios: any[] = [];
  permisos: any[] = [];
  usuarioSeleccionado: any = null;
  permisosVentana: number[] = [];
  ventanas: string[] = [
    'Personal', 'Inventario', 'Reportes', 'Bitacora', 'Usuarios', 'Lotes', 'OrdenProduccion', 'NotaSalida'
  ];
  ventanaSeleccionada: string = '';

  constructor(
    private permisosService: PermisosService,
    private loginService: LoginService,
    private http: HttpClient
  ) {}

  ngOnInit(): void {
    this.cargarUsuarios();
    this.cargarPermisos();
  }

  cargarUsuarios() {
  this.loginService.getuser().subscribe({
      next: (data: any) => {
        this.usuarios = data;
      },
      error: (error: any) => {
        console.error('Error al cargar usuarios:', error);
      }
    });
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

  seleccionarUsuario(usuario: any) {
    this.usuarioSeleccionado = usuario;
    this.cargarPermisosVentana();
  }

  cargarPermisosVentana() {
    if (!this.usuarioSeleccionado || !this.ventanaSeleccionada) {
      this.permisosVentana = [];
      return;
    }
    this.permisosService.obtenerPermisosDeUsuarioVentana(this.usuarioSeleccionado.name_user, this.ventanaSeleccionada).subscribe({
      next: (data: any) => {
        // data: {insertar, editar, eliminar, ver}
        this.permisosVentana = [];
        if (data.insertar) this.permisosVentana.push(1);
        if (data.editar) this.permisosVentana.push(2);
        if (data.eliminar) this.permisosVentana.push(3);
        if (data.ver) this.permisosVentana.push(4);
      },
      error: (error: any) => {
        console.error('Error al cargar permisos de la ventana:', error);
        this.permisosVentana = [];
      }
    });
  }

  tienePermiso(idPermiso: number): boolean {
    return this.permisosVentana.includes(idPermiso);
  }

  togglePermiso(idPermiso: number) {
    if (!this.usuarioSeleccionado || !this.ventanaSeleccionada) return;
    if (this.tienePermiso(idPermiso)) {
      this.permisosVentana = this.permisosVentana.filter(p => p !== idPermiso);
    } else {
      this.permisosVentana.push(idPermiso);
    }
  }

  onVentanaChange() {
    this.cargarPermisosVentana();
  }

  guardarPermisos() {
    if (!this.usuarioSeleccionado || !this.ventanaSeleccionada) return;
    const permiso = {
      ventana: this.ventanaSeleccionada,
      insertar: this.permisosVentana.includes(1),
      editar: this.permisosVentana.includes(2),
      eliminar: this.permisosVentana.includes(3),
      ver: this.permisosVentana.includes(4)
    };
    this.permisosService.asignarPermiso(this.usuarioSeleccionado.name_user, permiso).subscribe({
      next: () => {
        console.log('Permisos guardados correctamente');
      },
      error: (error: any) => {
        console.error('Error al guardar permisos:', error);
      }
    });
  }
}
