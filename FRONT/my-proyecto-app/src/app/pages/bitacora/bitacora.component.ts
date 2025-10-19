import { Component, OnInit } from '@angular/core';
import { BitacoraService } from '../../services_back/bitacora.service';

interface Bitacora {
  id_bitacora?: number;
  username: string;
  ip: string;
  fecha_hora: string;
  accion: string;
  descripcion: string;
}

@Component({
  selector: 'app-bitacora',
  templateUrl: './bitacora.component.html',
  styleUrls: ['./bitacora.component.css']
})
export class BitacoraComponent implements OnInit {
  // ---- Datos ----
  bitacoras: Bitacora[] = [];
  
  // ---- Filtros / búsqueda ----
  busqueda = '';
  filtroFecha = '';
  filtroAccion = '';
  
  // Catálogo de acciones comunes
  accionesCatalogo: string[] = [
    'Inicio de sesión',
    'Cierre de sesión',
    'Creación',
    'Modificación',
    'Eliminación',
    'Registro empleado'
  ];

  // ---- Modal / formulario ----
  showForm = false;
  form: Bitacora = this.nuevoForm();

  // Loading states
  isLoading = false;

  constructor(private bitacoraService: BitacoraService) {}

  ngOnInit(): void {
    this.cargarBitacoras();
  }

  // ---- Métodos de carga de datos ----
  cargarBitacoras(): void {
    this.isLoading = true;
    this.bitacoraService.getBitacoras().subscribe({
      next: (bitacoras) => {
        console.log('Bitácoras cargadas:', bitacoras);
        this.bitacoras = bitacoras;
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error al cargar bitácoras:', error);
        this.isLoading = false;
      }
    });
  }

  // ---- Lista filtrada para la tabla ----
  get filtrados(): Bitacora[] {
    return this.bitacoras.filter(b => {
      const okTexto = this.busqueda
        ? b.username.toLowerCase().includes(this.busqueda.toLowerCase()) ||
          b.accion.toLowerCase().includes(this.busqueda.toLowerCase()) ||
          b.descripcion.toLowerCase().includes(this.busqueda.toLowerCase())
        : true;
      
      const okFecha = this.filtroFecha 
        ? b.fecha_hora.startsWith(this.filtroFecha)
        : true;
      
      const okAccion = this.filtroAccion 
        ? b.accion.toLowerCase().includes(this.filtroAccion.toLowerCase())
        : true;
      
      return okTexto && okFecha && okAccion;
    });
  }

  // ---- Acciones UI ----
  abrirCrear(): void {
    this.form = this.nuevoForm();
    // Obtener usuario automáticamente desde el token
    const username = this.bitacoraService.getUserFromToken();
    if (username) {
      this.form.username = username;
    }
    this.showForm = true;
  }

  cancelar(): void {
    this.showForm = false;
  }

  guardar(): void {
    if (!this.form.accion) {
      alert('Por favor ingrese la acción');
      return;
    }

    // Usar el servicio para registrar la bitácora automáticamente
    this.bitacoraService.registrarAccion(this.form.accion, this.form.descripcion).subscribe({
      next: () => {
        console.log('Bitácora registrada exitosamente');
        alert('✅ Bitácora registrada exitosamente');
        
        // Recargar la lista completa desde el backend
        this.cargarBitacoras();
        
        this.showForm = false;
      },
      error: (error) => {
        console.error('Error al registrar bitácora:', error);
        
        let mensaje = 'Error al registrar la bitácora.';
        if (error.error?.message) {
          mensaje = error.error.message;
        }
        alert('❌ ' + mensaje);
      }
    });
  }

  limpiarFiltros(): void {
    this.busqueda = '';
    this.filtroFecha = '';
    this.filtroAccion = '';
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

  badgeAccion(accion: string): Record<string, boolean> {
    const accionLower = accion.toLowerCase();
    return {
      'badge-login': accionLower.includes('inicio') || accionLower.includes('login'),
      'badge-logout': accionLower.includes('cierre') || accionLower.includes('logout'),
      'badge-create': accionLower.includes('creación') || accionLower.includes('crear'),
      'badge-update': accionLower.includes('modificación') || accionLower.includes('actualizar'),
      'badge-delete': accionLower.includes('eliminación') || accionLower.includes('eliminar'),
      'badge-other': !accionLower.includes('inicio') && !accionLower.includes('cierre') && 
                     !accionLower.includes('creación') && !accionLower.includes('modificación') && 
                     !accionLower.includes('eliminación')
    };
  }

  formatearFecha(fechaHora: string): string {
    const date = new Date(fechaHora);
    return date.toLocaleString('es-ES', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }

  nuevoForm(): Bitacora {
    return {
      id_bitacora: 0,
      username: '',
      ip: '',
      fecha_hora: new Date().toISOString(),
      accion: '',
      descripcion: ''
    };
  }
}
