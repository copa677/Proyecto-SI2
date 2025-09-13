import { Component } from '@angular/core';

type EstadoUsuario = 'Activo' | 'Inactivo';
type TipoUsuario   = 'Administrador' | 'Supervisor' | 'Operario';

interface Usuario {
  id: number;
  nombre: string;
  email: string;
  tipo: TipoUsuario;
  estado: EstadoUsuario;
}

@Component({
  selector: 'app-usuarios',
  templateUrl: './usuarios.component.html',
  styleUrls: ['./usuarios.component.css']
})
export class UsuariosComponent {
  // Catálogos
  tiposCatalogo: TipoUsuario[] = ['Administrador', 'Supervisor', 'Operario'];

  // Filtros
  busqueda = '';
  filtroEstado: EstadoUsuario | '' = '';
  filtroTipo: TipoUsuario | '' = '';

  // Datos demo (en memoria)
  usuarios: Usuario[] = [
    { id: 1, nombre: 'Admin Usuario',   email: 'admin@ejemplo.com', tipo: 'Administrador', estado: 'Activo' },
    { id: 2, nombre: 'Juan Pérez',      email: 'juan@ejemplo.com',  tipo: 'Supervisor',    estado: 'Activo' },
    { id: 3, nombre: 'María González',  email: 'maria@ejemplo.com', tipo: 'Operario',      estado: 'Inactivo' },
  ];

  // Modal / Form
  showForm = false;
  editMode = false;
  form: Usuario = this.nuevoForm();

  // Lista filtrada
  get filtrados(): Usuario[] {
    return this.usuarios.filter(u => {
      const okTexto = this.busqueda
        ? (u.nombre + ' ' + u.email).toLowerCase().includes(this.busqueda.toLowerCase())
        : true;
      const okEstado = this.filtroEstado ? u.estado === this.filtroEstado : true;
      const okTipo   = this.filtroTipo   ? u.tipo   === this.filtroTipo   : true;
      return okTexto && okEstado && okTipo;
    });
  }

  // Acciones
  abrirCrear(): void {
    this.editMode = false;
    this.form = this.nuevoForm();
    if (this.filtroTipo)   this.form.tipo = this.filtroTipo as TipoUsuario;
    if (this.filtroEstado) this.form.estado = this.filtroEstado as EstadoUsuario;
    this.showForm = true;
  }

  abrirEditar(u: Usuario): void {
    this.editMode = true;
    this.form = { ...u };
    this.showForm = true;
  }

  cancelar(): void {
    this.showForm = false;
  }

  guardar(): void {
    if (!this.form.nombre || !this.form.email) return;

    if (this.editMode) {
      const idx = this.usuarios.findIndex(x => x.id === this.form.id);
      if (idx > -1) this.usuarios[idx] = { ...this.form };
    } else {
      const nuevoId = this.usuarios.length ? Math.max(...this.usuarios.map(x => x.id)) + 1 : 1;
      this.usuarios.unshift({ ...this.form, id: nuevoId });
    }
    this.showForm = false;
  }

  eliminar(u: Usuario): void {
    if (confirm(`¿Eliminar al usuario ${u.nombre}?`)) {
      this.usuarios = this.usuarios.filter(x => x.id !== u.id);
    }
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroEstado = '';
    this.filtroTipo = '';
  }

  // Helpers
  initials(nombre: string): string {
    if (!nombre) return '';
    return nombre.split(' ')
      .filter(Boolean)
      .map(p => p[0]?.toUpperCase() ?? '')
      .slice(0, 2)
      .join('');
  }

  badgeEstado(estado: EstadoUsuario): Record<string, boolean> {
    return {
      'badge-activo':   estado === 'Activo',
      'badge-inactivo': estado === 'Inactivo',
    };
  }

  nuevoForm(): Usuario {
    return {
      id: 0,
      nombre: '',
      email: '',
      tipo: 'Operario',
      estado: 'Activo',
    };
  }
}
