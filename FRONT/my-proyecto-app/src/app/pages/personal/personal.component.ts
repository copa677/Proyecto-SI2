import { Component } from '@angular/core';

type Rol = 'Administrador' | 'Supervisor' | 'Operario';

interface PersonalRow {
  id: number;
  nombre_completo: string;
  direccion: string;
  telefono: string;
  rol: Rol;
  fecha_nacimiento: string; // ISO 'YYYY-MM-DD'
}

@Component({
  selector: 'app-personal',
  templateUrl: './personal.component.html',
  styleUrls: ['./personal.component.css'],
})
export class PersonalComponent {
  // ===== Datos iniciales (mock de ejemplo) =====
  personal: PersonalRow[] = [
    {
      id: 1,
      nombre_completo: 'Juan Pérez',
      direccion: 'Av. Siempre Viva 123',
      telefono: '987654321',
      rol: 'Supervisor',
      fecha_nacimiento: '1990-04-12',
    },
    {
      id: 2,
      nombre_completo: 'María González',
      direccion: 'Calle Sol 456',
      telefono: '912345678',
      rol: 'Administrador',
      fecha_nacimiento: '1985-11-03',
    },
    {
      id: 3,
      nombre_completo: 'Carlos Rodríguez',
      direccion: 'Jr. Luna 789',
      telefono: '934567890',
      rol: 'Operario',
      fecha_nacimiento: '1998-01-25',
    },
  ];

  // ===== Estado UI =====
  showForm = false;
  editMode = false;
  filtroRol: '' | Rol = '';
  busqueda = '';

  // Modelo de formulario
  form: PersonalRow = this.vacio();

  // ===== Helpers =====
  vacio(): PersonalRow {
    return {
      id: 0,
      nombre_completo: '',
      direccion: '',
      telefono: '',
      rol: 'Operario',
      fecha_nacimiento: '',
    };
  }

  initials(nombre: string): string {
    return (nombre || '')
      .trim()
      .split(/\s+/)
      .map((x) => x[0])
      .slice(0, 2)
      .join('')
      .toUpperCase();
  }

  // ===== Acciones UI =====
  abrirCrear(): void {
    this.form = this.vacio();
    this.editMode = false;
    this.showForm = true;
  }

  abrirEditar(p: PersonalRow): void {
    this.form = { ...p }; // copia
    this.editMode = true;
    this.showForm = true;
  }

  cancelar(): void {
    this.showForm = false;
  }

  guardar(): void {
    const f = this.form;
    if (!f.nombre_completo.trim() || !f.rol.trim()) return;

    if (this.editMode) {
      this.personal = this.personal.map((p) => (p.id === f.id ? { ...f } : p));
    } else {
      const nuevoId = Math.max(...this.personal.map((x) => x.id), 0) + 1;
      this.personal = [...this.personal, { ...f, id: nuevoId }];
    }
    this.showForm = false;
  }

  eliminar(p: PersonalRow): void {
    if (confirm(`¿Eliminar a ${p.nombre_completo}?`)) {
      this.personal = this.personal.filter((x) => x.id !== p.id);
    }
  }

  // ===== Filtro calculado =====
  get filtrados(): PersonalRow[] {
    const q = this.busqueda.trim().toLowerCase();
    return this.personal.filter((p) => {
      const rolOk = this.filtroRol ? p.rol === this.filtroRol : true;
      const text = `${p.nombre_completo} ${p.direccion} ${p.telefono}`.toLowerCase();
      const buscaOk = q ? text.includes(q) : true;
      return rolOk && buscaOk;
    });
  }
}
