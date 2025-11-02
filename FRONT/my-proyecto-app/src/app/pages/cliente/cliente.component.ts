// src/app/pages/clientes/clientes.component.ts
import { Component, OnInit } from '@angular/core';
import { ToastrService } from 'ngx-toastr';
import { ClienteService, ClienteApiResponse, ClienteCreatePayload, ClienteUpdatePayload } from '../../services_back/cliente.service';

type Estado = 'activo' | 'inactivo';
type TipoUsuario = 'Cliente' | 'Administrador' | 'Supervisor'; // Ajusta según tus tipos de usuario

// Interfaz para la fila de la tabla (lo que viene de la API)
interface ClienteRow {
  id: number;
  id_usuario: number;
  estado: Estado;
  nombre_completo: string;
  direccion: string;
  telefono: string;
  fecha_nacimiento: string; // 'YYYY-MM-DD'
}

// Interfaz para el formulario (incluye campos de usuario para crear/editar)
interface ClienteForm {
  id: number;
  id_usuario: number;
  estado: Estado;
  nombre_completo: string;
  direccion: string;
  telefono: string;
  fecha_nacimiento: string;
  
  // Campos del usuario asociado
  name_user: string; // ('name_user' en tu API de creación)
  email: string;
  password?: string; // Siempre opcional
  tipo_usuario: TipoUsuario;
}


@Component({
  selector: 'app-clientes',
  templateUrl: './cliente.component.html',
  styleUrls: ['./cliente.component.css']
})
export class ClienteComponent implements OnInit {

  clientes: ClienteRow[] = [];
  
  showForm = false;
  editMode = false;
  filtroEstado: '' | Estado = '';
  busqueda = '';
  cargando = false;
  errorMsg = '';

  form: ClienteForm = this.vacio();

  constructor(
    private clienteSrv: ClienteService,
    private toastr: ToastrService
  ) { }

  ngOnInit(): void {
    this.cargarClientes();
  }

  cargarClientes(): void {
    this.cargando = true;
    this.errorMsg = '';
    this.clienteSrv.getClientes().subscribe({
      next: (lista) => {
        this.clientes = (lista || []).map((c: ClienteApiResponse) => ({
          id: c.id ?? 0,
          id_usuario: c.id_usuario ?? 0,
          estado: c.estado ?? 'inactivo',
          nombre_completo: c.nombre_completo ?? '',
          direccion: c.direccion ?? '',
          telefono: c.telefono ?? '',
          fecha_nacimiento: (c.fecha_nacimiento || '').slice(0, 10), // Aseguramos formato YYYY-MM-DD
        }));
        this.cargando = false;
      },
      error: (err) => {
        this.errorMsg = 'No se pudo cargar el listado de clientes.';
        console.error('Error getClientes:', err);
        this.toastr.error(this.errorMsg, 'Error');
        this.cargando = false;
      },
    });
  }

  vacio(): ClienteForm {
    return {
      id: 0,
      id_usuario: 0,
      estado: 'activo',
      nombre_completo: '',
      direccion: '',
      telefono: '',
      fecha_nacimiento: '',
      // Campos de usuario
      name_user: '',
      email: '',
      password: '',
      tipo_usuario: 'Cliente', // Default
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

  abrirEditar(c: ClienteRow): void {
    // Mapeamos la fila al formulario. Los campos de usuario (email, password)
    // se dejan en blanco. El usuario solo los llenará si desea cambiarlos.
    // La API (data.get) mantendrá los valores antiguos si no se envían.
    this.form = {
      ...c,
      name_user: '', // No se usa en editar
      email: '',       // Opcional para actualizar
      password: '',   // Opcional para actualizar
      tipo_usuario: 'Cliente', // Opcional para actualizar (deberías fetchear el real si pudieras)
    };
    this.editMode = true;
    this.showForm = true;
  }

  cancelar(): void { this.showForm = false; }

  guardar(): void {
    const f = this.form;
    
    // Validación básica
    if (!f.nombre_completo?.trim()) {
      this.toastr.warning('El nombre completo es obligatorio', 'Atención');
      return;
    }

    if (!this.editMode) {
      // --- CREAR ---
      if (!f.name_user?.trim() || !f.email?.trim() || !f.password?.trim()) {
        this.toastr.warning('Nombre de usuario, email y contraseña son obligatorios al crear', 'Atención');
        return;
      }

      const payload: ClienteCreatePayload = {
        nombre_completo: f.nombre_completo.trim(),
        direccion: f.direccion?.trim() ?? '',
        telefono: f.telefono?.trim() ?? '',
        fecha_nacimiento: f.fecha_nacimiento, // API espera 'YYYY-MM-DD'
        email: f.email.trim(),
        password: f.password, // No se trimea
        tipo_usuario: f.tipo_usuario,
        name_user: f.name_user.trim(),
      };

      this.cargando = true;
      this.clienteSrv.registrarCliente(payload).subscribe({
        next: () => {
          this.toastr.success('Cliente registrado correctamente', 'Éxito');
          this.showForm = false;
          this.cargarClientes(); // Recarga la lista
        },
        error: (err) => {
          this.toastr.error(err.error?.error || 'No se pudo registrar el cliente', 'Error');
          this.cargando = false;
        },
      });

    } else {
      // --- ACTUALIZAR ---
      const payload: ClienteUpdatePayload = {
        nombre_completo: f.nombre_completo.trim(),
        direccion: f.direccion?.trim() ?? '',
        telefono: f.telefono?.trim() ?? '',
        fecha_nacimiento: f.fecha_nacimiento,
        estado: f.estado,
        email: f.email?.trim() || undefined,
        password: f.password || undefined,
        tipo_usuario: f.tipo_usuario || undefined,
      };

      // Limpiamos campos opcionales si están vacíos
      if (!payload.email) delete payload.email;
      if (!payload.password) delete payload.password;
      if (!payload.tipo_usuario) delete payload.tipo_usuario;
      
      this.cargando = true;
      this.clienteSrv.actualizarCliente(f.id, payload).subscribe({
        next: () => {
          this.toastr.info('Cliente actualizado correctamente', 'Actualizado');
          this.showForm = false;
          this.cargarClientes(); // Recarga la lista
          this.editMode = false;
        },
        error: (err) => {
          this.toastr.error(err.error?.error || 'No se pudo actualizar el cliente', 'Error');
          this.cargando = false;
        },
      });
    }
  }

  eliminar(c: ClienteRow): void {
    if (!confirm(`¿Está seguro de eliminar a ${c.nombre_completo}? Esta acción también eliminará al usuario asociado.`)) {
      return;
    }

    this.cargando = true;
    this.clienteSrv.eliminarCliente(c.id).subscribe({
      next: () => {
        this.toastr.success('Cliente y usuario asociado eliminados', 'Eliminado');
        this.cargarClientes(); // Recarga la lista
      },
      error: (err) => {
        this.toastr.error(err.error?.error || 'No se pudo eliminar el cliente', 'Error');
        this.cargando = false;
      },
    });
  }

  // Getter para el pipe de filtrado
  get filtrados(): ClienteRow[] {
    const q = this.busqueda.trim().toLowerCase();
    
    return this.clientes.filter((c) => {
      // 1. Filtro por Estado
      const estadoOk = this.filtroEstado ? c.estado === this.filtroEstado : true;

      // 2. Filtro por Búsqueda
      const text = `${c.nombre_completo} ${c.direccion} ${c.telefono} ${c.id} ${c.id_usuario}`.toLowerCase();
      const buscaOk = q ? text.includes(q) : true;
      
      return estadoOk && buscaOk;
    });
  }
}