import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment.development';

type Estado = 'Presente' | 'Ausente' | 'Tarde' | 'Licencia';
type Turno  = 'Mañana (8:00–14:00)' | 'Tarde (14:00–20:00)' | 'Noche (20:00–02:00)';

interface Asistencia {
  id: number;
  nombre: string;
  fecha: string;   // ISO yyyy-MM-dd para simplificar el demo
  turno: Turno;
  estado: Estado;
}

// Mapeo entre lo que se muestra y lo que está en la BD
const TURNO_DISPLAY_TO_DB: Record<string, string> = {
  'Mañana (8:00–14:00)': 'mañana',
  'Tarde (14:00–20:00)': 'tarde',
  'Noche (20:00–02:00)': 'noche'
};

const TURNO_DB_TO_DISPLAY: Record<string, Turno> = {
  'mañana': 'Mañana (8:00–14:00)',
  'tarde': 'Tarde (14:00–20:00)',
  'noche': 'Noche (20:00–02:00)'
};

@Component({
  selector: 'app-asistencia',
  templateUrl: './asistencia.component.html',
  styleUrls: ['./asistencia.component.css']
})
export class AsistenciaComponent {
  private myAppUrl = environment.endpoint;
  private apiUrl = 'api/asistencias';
  private turnosUrl = 'api/turnos';
  private personalUrl = 'api/personal';

  // ---- Catálogos de apoyo ----
  turnosCatalogo: Turno[] = [
    'Mañana (8:00–14:00)',
    'Tarde (14:00–20:00)',
    'Noche (20:00–02:00)',
  ];
  estadosCatalogo: Estado[] = ['Presente', 'Ausente', 'Tarde', 'Licencia'];

  // Lista de personal para autocompletar
  personalList: any[] = [];
  turnosList: any[] = [];

  // Loading states
  isLoading = false;
  isLoadingTurnos = false;
  isLoadingPersonal = false;

  constructor(private http: HttpClient) {
    this.cargarAsistencias();
    this.cargarTurnos();
    this.cargarPersonal();
  }

  // ---- Filtros / búsqueda ----
  busqueda = '';
  filtroFecha = '';   // yyyy-MM-dd (input[type=date])
  filtroTurno: Turno | '' = '';
  filtroEstado: Estado | '' = '';

  // ---- Datos (cargados desde backend) ----
  asistencias: Asistencia[] = [];

  // ---- Modal / formulario ----
  showForm = false;
  editMode = false;
  form: Asistencia = this.nuevoForm();

  // ---- Métodos de carga de datos ----
  cargarAsistencias(): void {
    this.isLoading = true;
    this.http.get<any>(`${this.myAppUrl}${this.apiUrl}/listar`).subscribe({
      next: (response) => {
        console.log('Asistencias cargadas:', response);
        
        // Mapear los datos del backend al formato del frontend
        this.asistencias = response.asistencias.map((item: any) => {
          // Extraer solo el nombre del turno (ej: "mañana (07:00:00 - 15:00:00)" -> "mañana")
          let turnoNombre = item.turno_completo.split(' ')[0].toLowerCase();
          
          // Mapear a la versión display
          const turnoDisplay = TURNO_DB_TO_DISPLAY[turnoNombre] || 'Mañana (8:00–14:00)';
          
          return {
            id: item.id_control,
            nombre: item.nombre_personal,
            fecha: item.fecha,
            turno: turnoDisplay,
            estado: item.estado as Estado
          };
        });
        
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error al cargar asistencias:', error);
        this.isLoading = false;
        // No mostrar alert aquí, solo log, para no molestar al usuario
      }
    });
  }

  cargarTurnos(): void {
    this.isLoadingTurnos = true;
    this.http.get<any[]>(`${this.myAppUrl}${this.turnosUrl}/listar`).subscribe({
      next: (turnos) => {
        console.log('Turnos cargados:', turnos);
        this.turnosList = turnos.filter((t: any) => t.estado === 'activo');
        
        // Actualizar turnosCatalogo con los turnos reales
        this.turnosCatalogo = this.turnosList.map((t: any) => {
          const turnoNombre = t.turno.toLowerCase();
          return TURNO_DB_TO_DISPLAY[turnoNombre] || `${t.turno} (${t.hora_entrada} - ${t.hora_salida})`;
        }) as Turno[];
        
        this.isLoadingTurnos = false;
      },
      error: (error) => {
        console.error('Error al cargar turnos:', error);
        this.isLoadingTurnos = false;
      }
    });
  }

  cargarPersonal(): void {
    this.isLoadingPersonal = true;
    this.http.get<any[]>(`${this.myAppUrl}${this.personalUrl}/getEmpleados`).subscribe({
      next: (personal) => {
        console.log('Personal cargado:', personal);
        this.personalList = personal;
        this.isLoadingPersonal = false;
      },
      error: (error) => {
        console.error('Error al cargar personal:', error);
        this.isLoadingPersonal = false;
      }
    });
  }

  // ---- Resumen (demo “hoy”) ----
  get totalPersonal(): number {
    // Para demo: contamos personas únicas en “hoy” si coincide con filtroFecha, si no tomamos la fecha del primer registro
    const fechaRef = this.filtroFecha || (this.asistencias[0]?.fecha ?? this.hoyISO());
    const nombres = new Set(this.asistencias.filter(a => a.fecha === fechaRef).map(a => a.nombre));
    return nombres.size || this.asistencias.length;
  }
  get totalPresentes(): number {
    const fechaRef = this.filtroFecha || (this.asistencias[0]?.fecha ?? this.hoyISO());
    return this.asistencias.filter(a => a.fecha === fechaRef && a.estado === 'Presente').length;
  }
  get totalAusentes(): number {
    const fechaRef = this.filtroFecha || (this.asistencias[0]?.fecha ?? this.hoyISO());
    return this.asistencias.filter(a => a.fecha === fechaRef && a.estado === 'Ausente').length;
  }
  get porcentajePresentes(): number {
    const total = this.totalPersonal || 1;
    return Math.round((this.totalPresentes * 100) / total);
  }
  get porcentajeAusentes(): number {
    const total = this.totalPersonal || 1;
    return Math.round((this.totalAusentes * 100) / total);
  }

  // ---- Lista filtrada para la tabla ----
  get filtrados(): Asistencia[] {
    return this.asistencias.filter(a => {
      const okTexto = this.busqueda
        ? a.nombre.toLowerCase().includes(this.busqueda.toLowerCase())
        : true;
      const okFecha = this.filtroFecha ? a.fecha === this.filtroFecha : true;
      const okTurno = this.filtroTurno ? a.turno === this.filtroTurno : true;
      const okEstado = this.filtroEstado ? a.estado === this.filtroEstado : true;
      return okTexto && okFecha && okTurno && okEstado;
    });
  }

  // ---- Acciones UI ----
  abrirCrear(): void {
    this.editMode = false;
    this.form = this.nuevoForm();
    // si hay filtros puestos, precarga la fecha y el turno del filtro
    if (this.filtroFecha) this.form.fecha = this.filtroFecha;
    if (this.filtroTurno) this.form.turno = this.filtroTurno as Turno;
    this.showForm = true;
  }

  abrirEditar(a: Asistencia): void {
    this.editMode = true;
    this.form = { ...a };
    this.showForm = true;
  }

  cancelar(): void {
    this.showForm = false;
  }

  guardar(): void {
    if (!this.form.nombre || !this.form.fecha) {
      alert('Por favor complete todos los campos requeridos');
      return;
    }

    // Convertir el turno del display al valor de la BD
    const turnoParaBD = TURNO_DISPLAY_TO_DB[this.form.turno] || 'mañana';

    // Preparar datos para enviar al backend
    const datosParaBackend = {
      nombre: this.form.nombre,
      fecha: this.form.fecha,
      turno: turnoParaBD,
      estado: this.form.estado
    };

    if (this.editMode) {
      // Actualizar asistencia existente en el backend
      this.http.put(`${this.myAppUrl}${this.apiUrl}/actualizar/${this.form.id}`, datosParaBackend).subscribe({
        next: (response: any) => {
          console.log('Asistencia actualizada:', response);
          alert('✅ Asistencia actualizada exitosamente');
          // Recargar la lista completa desde el backend
          this.cargarAsistencias();
          this.showForm = false;
        },
        error: (error) => {
          console.error('Error al actualizar asistencia:', error);
          let mensaje = 'Error al actualizar la asistencia.';
          if (error.error?.error) {
            mensaje = error.error.error;
          }
          alert('❌ ' + mensaje);
        }
      });
    } else {
      // Crear nueva asistencia
      this.http.post(`${this.myAppUrl}${this.apiUrl}/agregar`, datosParaBackend).subscribe({
        next: (response: any) => {
          console.log('Asistencia registrada:', response);
          alert('✅ Asistencia registrada exitosamente');
          // Recargar la lista completa desde el backend
          this.cargarAsistencias();
          this.showForm = false;
        },
        error: (error) => {
          console.error('Error al registrar asistencia:', error);
          let mensaje = 'Error al registrar la asistencia.';
          if (error.error?.error) {
            mensaje = error.error.error;
          }
          alert('❌ ' + mensaje);
        }
      });
    }
  }

  eliminar(a: Asistencia): void {
    if (confirm(`¿Eliminar el registro de ${a.nombre} (${a.fecha})?`)) {
      this.asistencias = this.asistencias.filter(x => x.id !== a.id);
    }
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroFecha = '';
    this.filtroTurno = '';
    this.filtroEstado = '';
  }

  // ---- Helpers de vista ----
  initials(nombre: string): string {
    if (!nombre) return '';
    return nombre.split(' ')
      .filter(Boolean)
      .map(p => p[0]?.toUpperCase() ?? '')
      .slice(0, 2)
      .join('');
  }

  badgeEstado(estado: Estado): Record<string, boolean> {
    return {
      'badge-presente': estado === 'Presente',
      'badge-ausente': estado === 'Ausente',
      'badge-tarde': estado === 'Tarde',
      'badge-licencia': estado === 'Licencia',
    };
  }

  descripcionTurno(t: Turno): string {
    if (t.startsWith('Mañana')) return '8:00 AM - 2:00 PM';
    if (t.startsWith('Tarde'))  return '2:00 PM - 8:00 PM';
    return '8:00 PM - 2:00 AM';
  }

  contarPorTurno(t: Turno): number {
    const fechaRef = this.filtroFecha || (this.asistencias[0]?.fecha ?? this.hoyISO());
    return this.asistencias.filter(a => a.fecha === fechaRef && a.turno === t).length;
    // (en real integrarías la lógica según tu backend)
  }

  nuevoForm(): Asistencia {
    return {
      id: 0,
      nombre: '',
      fecha: this.hoyISO(),
      turno: 'Mañana (8:00–14:00)',
      estado: 'Presente'
    };
  }

  hoyISO(): string {
    const d = new Date();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${d.getFullYear()}-${mm}-${dd}`;
  }
}
