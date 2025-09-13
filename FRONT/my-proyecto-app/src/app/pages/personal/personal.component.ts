import { Component } from '@angular/core';

type Rol = 'Administrador' | 'Supervisor' | 'Operario';

interface Personal {
  id: number;
  nombre: string;
  email: string;
  rol: Rol;
  permisos: string[]; // ['Asistencia','Reportes','Admin','Básico']
}

@Component({
  selector: 'app-personal',
  templateUrl: './personal.component.html',
  styleUrls: ['./personal.component.css'],
})
export class PersonalComponent {
  // ===== Datos iniciales (mock) =====
  personal: Personal[] = [
    { id: 1, nombre: 'Juan Pérez',      email: 'juan.perez@ejemplo.com',      rol: 'Supervisor',    permisos: ['Asistencia','Reportes'] },
    { id: 2, nombre: 'María González',  email: 'maria.gonzalez@ejemplo.com',  rol: 'Administrador', permisos: ['Asistencia','Reportes','Admin'] },
    { id: 3, nombre: 'Carlos Rodríguez',email: 'carlos.rodriguez@ejemplo.com',rol: 'Operario',      permisos: ['Básico'] },
  ];

  // ===== Estado UI =====
  showForm = false;       // muestra/oculta modal
  editMode = false;       // crear vs editar
  filtroRol: '' | Rol = ''; // filtro de rol
  busqueda = '';          // texto de búsqueda

  // Permisos disponibles para checkboxes
  permisosCatalogo = ['Asistencia','Reportes','Admin','Básico'];

  // Modelo de formulario
  form: Personal = this.vacio();

  // ===== Helpers =====
  vacio(): Personal {
    return { id: 0, nombre: '', email: '', rol: 'Operario', permisos: [] };
  }

  initials(nombre: string): string {
    return nombre.split(' ').map(x => x[0]).slice(0, 2).join('').toUpperCase();
  }

  // ===== Acciones UI =====
  abrirCrear(): void {
    this.form = this.vacio();
    this.editMode = false;
    this.showForm = true;
  }

  abrirEditar(p: Personal): void {
    this.form = { ...p, permisos: [...p.permisos] }; // copia
    this.editMode = true;
    this.showForm = true;
  }

  cancelar(): void {
    this.showForm = false;
  }

  togglePermiso(valor: string, checked: boolean): void {
    const i = this.form.permisos.indexOf(valor);
    if (checked && i === -1) this.form.permisos.push(valor);
    if (!checked && i !== -1) this.form.permisos.splice(i, 1);
  }

  guardar(): void {
    if (!this.form.nombre.trim() || !this.form.email.trim()) return;

    if (this.editMode) {
      this.personal = this.personal.map(p => p.id === this.form.id ? { ...this.form } : p);
    } else {
      const nuevoId = Math.max(...this.personal.map(x => x.id), 0) + 1;
      this.personal = [...this.personal, { ...this.form, id: nuevoId }];
    }
    this.showForm = false;
  }

  eliminar(p: Personal): void {
    if (confirm(`¿Eliminar a ${p.nombre}?`)) {
      this.personal = this.personal.filter(x => x.id !== p.id);
    }
  }

  // ===== Filtro calculado =====
  get filtrados(): Personal[] {
    return this.personal.filter(p => {
      const rolOk = this.filtroRol ? p.rol === this.filtroRol : true;
      const text = (p.nombre + ' ' + p.email).toLowerCase();
      const buscaOk = this.busqueda ? text.includes(this.busqueda.toLowerCase()) : true;
      return rolOk && buscaOk;
    });
  }
}
