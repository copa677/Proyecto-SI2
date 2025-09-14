import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services_back/login.service';
import { ToastrService } from 'ngx-toastr';
// import { Usuario } from 'src/interface/user'; // <- quítalo si no lo usas

// View-model que usa TU HTML
type ViewUsuario = {
  id: number;
  nombre: string;           // ← viene de name_user
  email: string;
  estado: 'Activo' | 'Inactivo';
  tipo: string;             // ← viene de tipo_usuario
};

type FormUsuario = Partial<ViewUsuario> & {
  password?: string;        // ← para crear
  nombre: string;
  email: string;
  estado: 'Activo' | 'Inactivo';
  tipo: string;
};

@Component({
  selector: 'app-usuarios',
  templateUrl: './usuarios.component.html',
  styleUrls: ['./usuarios.component.css']
})
export class UsuariosComponent implements OnInit {
  // filtros/búsqueda
  busqueda = '';
  filtroEstado: '' | 'Activo' | 'Inactivo' = '';
  filtroTipo: string | '' = '';

  // El listado seguirá mostrando tipo/estado que llegan del back
  tiposCatalogo = ['Administrador','Supervisor','Operario'];

  // datos
  usuarios: ViewUsuario[] = [];
  filtrados: ViewUsuario[] = [];

  // modal
  showForm = false;
  editMode = false;
  form: FormUsuario = { nombre: '', email: '', password: '', estado: 'Activo', tipo: 'empleado' };

  loading = false;

  constructor(
    private api: LoginService,
    private toastr: ToastrService,
  ) {}

  ngOnInit(): void {
    this.cargar();
  }

  // Helpers UI
  initials(nombre: string): string {
    if (!nombre) return '';
    return nombre.trim().split(/\s+/).slice(0,2).map(s => s[0]).join('').toUpperCase();
  }

  badgeEstado(estado: string) {
    return {
      'bg-green-100 text-green-800': estado === 'Activo',
      'bg-gray-200 text-gray-700': estado === 'Inactivo'
    };
  }

  limpiarFiltros() {
    this.busqueda = '';
    this.filtroEstado = '';
    this.filtroTipo = '';
    this.aplicarFiltros();
  }

  // ===== CRUD =====
  cargar() {
    this.loading = true;
    this.api.getuser().subscribe({
      next: (rows: any[]) => {
        // Mapeo: backend → view-model (lo que tu HTML espera)
        this.usuarios = (rows ?? []).map(r => ({
          id: Number(r.id),
          nombre: r.name_user ?? '',
          email: r.email ?? '',
          estado: (r.estado as 'Activo'|'Inactivo') ?? 'Activo',
          tipo: r.tipo_usuario ?? ''
        }));
        this.aplicarFiltros();
      },
      error: (e) => {
        console.error(e);
        this.toastr.error('No se pudieron cargar los usuarios', 'Error');
      },
      complete: () => this.loading = false
    });
  }

  aplicarFiltros() {
    const q = this.busqueda.trim().toLowerCase();
    this.filtrados = this.usuarios.filter(u => {
      const byQ = !q || `${u.nombre} ${u.email} ${u.tipo}`.toLowerCase().includes(q);
      const byE = !this.filtroEstado || u.estado === this.filtroEstado;
      const byT = !this.filtroTipo || u.tipo === this.filtroTipo;
      return byQ && byE && byT;
    });
  }

  abrirCrear() {
    this.editMode = false;
    // por requisitos: tipo = "empleado", estado = "Activo"
    this.form = { nombre: '', email: '', password: '', estado: 'Activo', tipo: 'empleado' };
    this.showForm = true;
  }

  abrirEditar(u: ViewUsuario) {
    this.editMode = true;
    this.form = { id: u.id, nombre: u.nombre, email: u.email, estado: u.estado, tipo: u.tipo };
    this.showForm = true;
  }

  cancelar() {
    this.showForm = false;
  }

  guardar() {
    if (this.editMode && this.form.id) {
      // Por ahora no hay endpoint de UPDATE en tu backend público.
      this.toastr.info('La edición aún no está disponible desde esta pantalla.', 'Aviso');
      return;
    }

    // Crear: username (name_user), password, email
    const payloadCreate = {
      name_user   : this.form.nombre?.trim(),
      password    : this.form.password?.trim(),
      email       : this.form.email?.trim(),
      tipo_usuario: 'empleado', // fijo
      estado      : 'Activo'    // fijo
    };

    if (!payloadCreate.name_user || !payloadCreate.email || !payloadCreate.password) {
      this.toastr.warning('Completa username, email y password', 'Campos requeridos');
      return;
    }

    this.api.register(payloadCreate as any).subscribe({
      next: () => {
        this.toastr.success('Usuario creado', 'Éxito');
        this.showForm = false;
        this.cargar();
      },
      error: (e: any) => {
        console.error(e);
        this.toastr.error('No se pudo crear', 'Error');
      }
    });
  }
}
