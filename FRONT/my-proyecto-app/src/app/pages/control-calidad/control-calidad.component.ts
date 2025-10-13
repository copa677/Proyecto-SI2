import { Component, OnInit } from '@angular/core';
import { ControlCalidadService } from '../../services_back/control-calidad.service';
import { ControlCalidad } from '../../../interface/controlCalidad';

@Component({
  selector: 'app-control-calidad',
  templateUrl: './control-calidad.component.html',
  styleUrls: ['./control-calidad.component.css']
})
export class ControlCalidadComponent implements OnInit {
  controles: ControlCalidad[] = [];
  selectedControl: ControlCalidad | null = null;
  showForm = false;
  formData: Partial<ControlCalidad> = {};
  searchTerm = '';

  constructor(private controlCalidadService: ControlCalidadService) {}

  ngOnInit(): void {
    this.getControles();
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
    this.formData = control ? { ...control } : {
      observaciones: '',
      resultado: 'Pendiente',
      fehca_hora: new Date().toISOString(),
      nombre_personal: '',
      id_trazabilidad: 0
    };
  }

  closeForm() {
    this.showForm = false;
    this.formData = {};
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
}
