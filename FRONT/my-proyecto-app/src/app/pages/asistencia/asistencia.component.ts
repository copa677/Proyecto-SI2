import { Component } from '@angular/core';

type Estado = 'Presente' | 'Ausente' | 'Tarde' | 'Licencia';
type Turno  = 'Mañana (8:00–14:00)' | 'Tarde (14:00–20:00)' | 'Noche (20:00–02:00)';

interface Asistencia {
  id: number;
  nombre: string;
  fecha: string;   // ISO yyyy-MM-dd para simplificar el demo
  turno: Turno;
  estado: Estado;
}

@Component({
  selector: 'app-asistencia',
  templateUrl: './asistencia.component.html',
  styleUrls: ['./asistencia.component.css']
})
export class AsistenciaComponent {
  // ---- Catálogos de apoyo ----
  turnosCatalogo: Turno[] = [
    'Mañana (8:00–14:00)',
    'Tarde (14:00–20:00)',
    'Noche (20:00–02:00)',
  ];
  estadosCatalogo: Estado[] = ['Presente', 'Ausente', 'Tarde', 'Licencia'];

  // ---- Filtros / búsqueda ----
  busqueda = '';
  filtroFecha = '';   // yyyy-MM-dd (input[type=date])
  filtroTurno: Turno | '' = '';
  filtroEstado: Estado | '' = '';

  // ---- Datos demo (en memoria) ----
  asistencias: Asistencia[] = [
    { id: 1, nombre: 'Juan Pérez',    fecha: '2025-04-16', turno: 'Mañana (8:00–14:00)', estado: 'Presente' },
    { id: 2, nombre: 'María González',fecha: '2025-04-16', turno: 'Mañana (8:00–14:00)', estado: 'Presente' },
    { id: 3, nombre: 'Carlos Rodríguez', fecha: '2025-04-16', turno: 'Tarde (14:00–20:00)', estado: 'Ausente' },
  ];

  // ---- Modal / formulario ----
  showForm = false;
  editMode = false;
  form: Asistencia = this.nuevoForm();

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
    if (!this.form.nombre || !this.form.fecha) return;

    if (this.editMode) {
      const i = this.asistencias.findIndex(x => x.id === this.form.id);
      if (i > -1) this.asistencias[i] = { ...this.form };
    } else {
      const nuevoId = this.asistencias.length
        ? Math.max(...this.asistencias.map(x => x.id)) + 1
        : 1;
      this.asistencias.unshift({ ...this.form, id: nuevoId });
    }
    this.showForm = false;
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
