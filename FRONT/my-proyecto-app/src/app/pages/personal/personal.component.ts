import { Component, OnInit } from '@angular/core';
import { EmpleadoService } from '../../services_back/empleado.service';
import { Empleado } from 'src/interface/empleado';
import { ToastrService } from 'ngx-toastr';

type Rol = 'Administrador' | 'Supervisor' | 'Operario';
type Estado = 'activo' | 'inactivo';

interface PersonalRow {
  id: number;
  id_usuario: number;
  estado: Estado;
  nombre_completo: string;
  nombre_usuario: string;
  direccion: string;
  telefono: string;
  rol: Rol;
  fecha_nacimiento: string; // 'YYYY-MM-DD'
}

@Component({
  selector: 'app-personal',
  templateUrl: './personal.component.html',
  styleUrls: ['./personal.component.css'],
})
export class PersonalComponent implements OnInit {
  personal: PersonalRow[] = [];

  showForm = false;
  editMode = false;
  filtroRol: '' | Rol = '';
  busqueda = '';
  cargando = false;
  errorMsg = '';

  form: PersonalRow = this.vacio();

  constructor(
    private empleadoSrv: EmpleadoService,
    private toastr: ToastrService
  ) { }  // <-- INYECTAMOS

  ngOnInit(): void {
    this.cargarEmpleados();
  }

  cargarEmpleados(): void {
    this.cargando = true;
    this.errorMsg = '';
    this.empleadoSrv.getEmpleados().subscribe({
      next: (lista) => {
        this.personal = (lista || []).map((e: any) => ({
          id: e.id_personal ?? e.id ?? 0,
          id_usuario: e.id_usuario ?? 0,
          estado: (e.estado as Estado) ?? 'activo',
          nombre_completo: e.nombre_completo ?? '',
          nombre_usuario: e.username ?? '',
          direccion: e.direccion ?? '',
          telefono: e.telefono ?? '',
          rol: (e.rol as Rol) ?? 'Operario',
          fecha_nacimiento:
            typeof e.fecha_nacimiento === 'string'
              ? e.fecha_nacimiento.slice(0, 10)
              : (e.fecha_nacimiento instanceof Date
                ? e.fecha_nacimiento.toISOString().slice(0, 10)
                : ''),
        }));
        this.cargando = false;
      },
      error: (err) => {
        this.errorMsg = 'No se pudo cargar el personal.';
        console.error('Error getEmpleados:', err);
        this.cargando = false;
      },
    });
  }

  vacio(): PersonalRow {
    return {
      id: 0,
      id_usuario: 0,
      estado: 'activo',
      nombre_completo: '',
      nombre_usuario: '',
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

  abrirCrear(): void {
    this.form = this.vacio();
    this.editMode = false;
    this.showForm = true;
  }

  abrirEditar(p: PersonalRow): void {
    this.form = { ...p, id_usuario: p.id_usuario, nombre_usuario: p.nombre_usuario };
    this.editMode = true;
    this.showForm = true;
  }

  cancelar(): void { this.showForm = false; }

  // ====== AQUÍ CONECTAMOS REGISTRO ======
  private toEmpleadoPayloadFromForm(): Empleado {
    // backend acepta Date o string; usamos Date (tu interfaz Empleado lo pide así)
    const fecha = this.form.fecha_nacimiento
      ? new Date(this.form.fecha_nacimiento + 'T00:00:00')
      : new Date();

    return {
      // OJO: para registrar NO requiere id_usuario; para actualizar/eliminar SÍ.
      id_personal: this.form.id || undefined,     // opcional
      id_usuario: this.form.id_usuario || undefined,
      nombre_completo: this.form.nombre_completo.trim(),
      direccion: this.form.direccion?.trim() ?? '',
      telefono: this.form.telefono?.trim() ?? '',
      rol: this.form.rol,
      fecha_nacimiento: fecha,
      estado: this.form.estado,
      username: this.form.nombre_usuario?.trim() ?? '',
      // email?: si luego lo usas, agrégalo al form y al payload
    };
  }
  guardar(): void {
    const f = this.form;
    if (!f.nombre_completo?.trim() || !f.rol?.trim()) return;

    if (!this.editMode) {
      const fecha = f.fecha_nacimiento
        ? new Date(f.fecha_nacimiento + 'T00:00:00')
        : new Date();
      const payload: Empleado = {
        nombre_completo: f.nombre_completo.trim(),
        direccion: f.direccion?.trim() ?? '',
        telefono: f.telefono?.trim() ?? '',
        rol: f.rol,
        fecha_nacimiento: fecha,
        estado: f.estado,
        username: f.nombre_usuario?.trim() ?? ''
      };
      this.cargando = true;
      this.empleadoSrv.registrarEmpleados(payload).subscribe({
        next: () => {
          this.toastr.success('Empleado registrado correctamente', 'Éxito');
          this.showForm = false;
          this.cargarEmpleados();
        },
        error: (err) => {
          this.toastr.error('No se pudo registrar el empleado', 'Error');
          this.errorMsg = 'No se pudo registrar el empleado.';
          this.cargando = false;
        },
      });
    } else {
      const fecha = f.fecha_nacimiento
        ? new Date(f.fecha_nacimiento + 'T00:00:00')
        : new Date();
      const payload: Empleado = {
        nombre_completo: f.nombre_completo.trim(),
        direccion: f.direccion?.trim() ?? '',
        telefono: f.telefono?.trim() ?? '',
        rol: f.rol,
        fecha_nacimiento: fecha,
        estado: f.estado,
        username: f.nombre_usuario?.trim() ?? '',
        id_usuario: f.id_usuario
      };
      this.cargando = true;
      this.empleadoSrv.actualizar_Empleados(payload).subscribe({
        next: () => {
          this.toastr.info('Empleado actualizado correctamente', 'Actualizado');
          this.showForm = false;
          this.cargarEmpleados();
          this.editMode = false;
        },
        error: (err) => {
          this.toastr.error('No se pudo actualizar el empleado', 'Error');
          this.errorMsg = 'No se pudo actualizar el empleado.';
          this.cargando = false;
        },
      });
    }
  }

  eliminar(p: PersonalRow): void {
    // ELIMINAR -> eliminar_Empleado (tu backend espera id_usuario)
    if (!p.id_usuario) {
      alert('No se puede eliminar: falta id_usuario.');
      return;
    }
    if (!confirm(`¿Eliminar a ${p.nombre_completo}?`)) return;

    this.cargando = true;
    const payload: Empleado = {
      // Solo necesita id_usuario para tu endpoint /eliminar
      nombre_completo: '', direccion: '', telefono: '',
      rol: 'Operario', fecha_nacimiento: new Date(), estado: 'activo',
      id_usuario: p.id_usuario
    };

    this.empleadoSrv.eliminar_Empleado(payload).subscribe({
      next: () => this.cargarEmpleados(),
      error: (err) => {
        this.errorMsg = 'No se pudo eliminar el empleado.';
        console.error('Error eliminar_Empleado:', err);
        this.cargando = false;
      },
    });
  }

  get filtrados(): PersonalRow[] {
    const q = this.busqueda.trim().toLowerCase();
    return this.personal.filter((p) => {
      const rolOk = this.filtroRol ? p.rol === this.filtroRol : true;
      const text = `${p.nombre_completo} ${p.nombre_usuario} ${p.direccion} ${p.telefono}`.toLowerCase();
      const buscaOk = q ? text.includes(q) : true;
      return rolOk && buscaOk;
    });
  }
}
