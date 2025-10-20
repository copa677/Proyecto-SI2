import { Component, OnInit } from '@angular/core';
import { TrazabilidadService } from '../../services_back/trazabilidad.service';
import { Trazabilidad } from '../../../interface/trazabilidad';

@Component({
  selector: 'app-trazabilidad',
  templateUrl: './trazabilidad.component.html',
  styleUrls: ['./trazabilidad.component.css']
})
export class TrazabilidadComponent implements OnInit {
  trazabilidades: Trazabilidad[] = [];
  selectedTrazabilidad: Trazabilidad | null = null;
  showForm = false;
  formData: Partial<Trazabilidad> = {};
  searchTerm = '';

  constructor(private trazabilidadService: TrazabilidadService) {}

  ngOnInit(): void {
    this.getTrazabilidades();
  }

  getTrazabilidades() {
    this.trazabilidadService.getTrazabilidades().subscribe(
      (data: Trazabilidad[]) => {
        this.trazabilidades = data;
      },
      (error: any) => {
        console.error('Error al obtener trazabilidades:', error);
      }
    );
  }

  get filteredTrazabilidades() {
    if (!this.searchTerm) return this.trazabilidades;
    return this.trazabilidades.filter(traz => 
      traz.proceso?.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
      traz.descripcion_proceso?.toLowerCase().includes(this.searchTerm.toLowerCase())
    );
  }

  selectTrazabilidad(trazabilidad: Trazabilidad) {
    this.selectedTrazabilidad = trazabilidad;
    this.showForm = false;
  }

  openForm(trazabilidad?: Trazabilidad) {
    this.showForm = true;
    this.formData = trazabilidad ? { ...trazabilidad } : {
      proceso: '',
      descripcion_proceso: '',
      fecha_registro: new Date().toISOString(),
      hora_inicio: '08:00:00',
      hora_fin: '17:00:00',
      cantidad: 0,
      estado: 'En Proceso',
      id_personal: 0,
      id_orden: 0
    };
  }

  closeForm() {
    this.showForm = false;
    this.formData = {};
  }

  saveTrazabilidad() {
    if (this.formData.id_trazabilidad) {
      // Actualizar trazabilidad existente
      this.trazabilidadService.actualizarTrazabilidad(this.formData.id_trazabilidad, this.formData as Trazabilidad).subscribe(
        () => {
          this.getTrazabilidades();
          this.closeForm();
        },
        (error: any) => {
          console.error('Error al actualizar trazabilidad:', error);
        }
      );
    } else {
      // Crear nueva trazabilidad
      this.trazabilidadService.insertarTrazabilidad(this.formData as Trazabilidad).subscribe(
        () => {
          this.getTrazabilidades();
          this.closeForm();
        },
        (error: any) => {
          console.error('Error al crear trazabilidad:', error);
        }
      );
    }
  }

  deleteTrazabilidad(id: number) {
    if (confirm('¿Está seguro de eliminar esta trazabilidad?')) {
      this.trazabilidadService.eliminarTrazabilidad(id).subscribe(
        () => {
          this.getTrazabilidades();
          if (this.selectedTrazabilidad?.id_trazabilidad === id) {
            this.selectedTrazabilidad = null;
          }
        },
        (error: any) => {
          console.error('Error al eliminar trazabilidad:', error);
        }
      );
    }
  }

  getEstadoClass(estado: string): string {
    switch(estado) {
      case 'Completado': return 'bg-green-100 text-green-800';
      case 'En Proceso': return 'bg-blue-100 text-blue-800';
      case 'Pendiente': return 'bg-yellow-100 text-yellow-800';
      case 'Cancelado': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  }

  calcularProgreso(horaInicio: string, horaFin: string): number {
    if (!horaInicio || !horaFin) return 0;
    
    const ahora = new Date();
    const hoy = ahora.toISOString().split('T')[0];
    
    const inicio = new Date(`${hoy}T${horaInicio}`);
    const fin = new Date(`${hoy}T${horaFin}`);
    const actual = ahora;
    
    if (actual < inicio) return 0;
    if (actual > fin) return 100;
    
    const totalTiempo = fin.getTime() - inicio.getTime();
    const tiempoTranscurrido = actual.getTime() - inicio.getTime();
    
    return Math.round((tiempoTranscurrido / totalTiempo) * 100);
  }
}
