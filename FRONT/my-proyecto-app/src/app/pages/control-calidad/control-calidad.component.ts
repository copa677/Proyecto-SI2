import { Component, OnInit } from '@angular/core';
import { ControlCalidadService } from '../../services_back/control-calidad.service';
import { PersonalService } from '../../services_back/personal.service';
import { TrazabilidadService } from '../../services_back/trazabilidad.service';
import { ControlCalidad } from '../../../interface/control-calidad';
import { Personal } from '../../../interface/personal';
import { Trazabilidad } from '../../../interface/trazabilidad';

@Component({
  selector: 'app-control-calidad',
  templateUrl: './control-calidad.component.html',
  styleUrls: ['./control-calidad.component.css']
})
export class ControlCalidadComponent implements OnInit {
  controles: ControlCalidad[] = [];
  personales: Personal[] = [];
  trazabilidades: Trazabilidad[] = [];
  
  selectedControl: ControlCalidad | null = null;
  selectedTrazabilidadDetails: Trazabilidad | null = null;
  showForm = false;
  formData: Partial<ControlCalidad> = {};
  searchTerm = '';

  constructor(
    private controlCalidadService: ControlCalidadService,
    private personalService: PersonalService,
    private trazabilidadService: TrazabilidadService
  ) {}

  ngOnInit(): void {
    this.getControles();
    this.loadInitialData();
  }

  getControles() {
    this.controlCalidadService.getControles().subscribe(
      (data: ControlCalidad[]) => {
        this.controles = data;
      },
      (error: any) => {
        console.error('Error al obtener controles:', error);
      }
    );
  }

  loadInitialData() {
    this.personalService.getPersonales().subscribe(data => this.personales = data);
    this.trazabilidadService.getTrazabilidades().subscribe(data => this.trazabilidades = data);
  }

  get filteredControles() {
    if (!this.searchTerm) return this.controles;
    return this.controles.filter(ctrl => 
      ctrl.resultado?.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
      ctrl.observaciones?.toLowerCase().includes(this.searchTerm.toLowerCase())
    );
  }

  selectControl(control: ControlCalidad) {
    this.selectedControl = control;
    this.showForm = false;
  }

  openForm(control?: ControlCalidad) {
    this.showForm = true;
    this.selectedTrazabilidadDetails = null;
    this.formData = control ? { ...control } : {
      observaciones: '',
      resultado: 'Pendiente',
      fecha_hora: new Date().toISOString().substring(0, 16),
      id_personal: undefined,
      id_trazabilidad: undefined
    };
    if (control && control.id_trazabilidad) {
      this.onTrazabilidadChange(control.id_trazabilidad);
    }
  }

  onTrazabilidadChange(id_trazabilidad: number) {
    this.selectedTrazabilidadDetails = this.trazabilidades.find(t => t.id_trazabilidad === +id_trazabilidad) || null;
  }

  closeForm() {
    this.showForm = false;
    this.formData = {};
    this.selectedTrazabilidadDetails = null;
  }

  saveControl() {
    if (this.formData.id_control) {
      // Actualizar control existente
      this.controlCalidadService.actualizarControl(this.formData.id_control, this.formData as ControlCalidad).subscribe(
        () => {
          this.getControles();
          this.closeForm();
        },
        (error: any) => {
          console.error('Error al actualizar control:', error);
        }
      );
    } else {
      // Crear nuevo control
      this.controlCalidadService.insertarControl(this.formData as ControlCalidad).subscribe(
        () => {
          this.getControles();
          this.closeForm();
        },
        (error: any) => {
          console.error('Error al crear control:', error);
        }
      );
    }
  }

  deleteControl(id: number) {
    if (confirm('¿Está seguro de eliminar este control de calidad?')) {
      this.controlCalidadService.eliminarControl(id).subscribe(
        () => {
          this.getControles();
          if (this.selectedControl?.id_control === id) {
            this.selectedControl = null;
          }
        },
        (error: any) => {
          console.error('Error al eliminar control:', error);
        }
      );
    }
  }

  getResultadoClass(resultado: string): string {
    switch(resultado) {
      case 'Aprobado': return 'bg-green-100 text-green-800';
      case 'Rechazado': return 'bg-red-100 text-red-800';
      case 'Pendiente': return 'bg-yellow-100 text-yellow-800';
      case 'En Revisión': return 'bg-blue-100 text-blue-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  }

  getPersonalNombre(id?: number): string {
    if (!id) return 'No asignado';
    const personal = this.personales.find(p => p.id === id);
    return personal ? personal.nombre_completo : 'Desconocido';
  }
}
