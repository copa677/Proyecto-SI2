import { Component, OnInit } from '@angular/core';
import { TurnosService } from '../../services_back/turnos.service';
import { Turno } from '../../../interface/turno';

@Component({
  selector: 'app-turnos',
  templateUrl: './turnos.component.html',
  styleUrls: ['./turnos.component.css']
})
export class TurnosComponent implements OnInit {
  turnos: Turno[] = [];
  selectedTurno: Turno | null = null;
  showForm = false;
  formData: Partial<Turno> = {};

  constructor(private turnosService: TurnosService) {}

  ngOnInit(): void {
    this.getTurnos();
  }

  getTurnos() {
    this.turnosService.getTurnos().subscribe(
      (data: Turno[]) => {
        this.turnos = data;
      },
      (error: any) => {
        console.error('Error al obtener turnos:', error);
      }
    );
  }

  selectTurno(turno: Turno) {
    this.selectedTurno = turno;
    this.showForm = false;
  }

  openForm(turno?: Turno) {
    this.showForm = true;
    this.formData = turno ? { ...turno } : {
      turno: '',
      hora_entrada: '',
      hora_salida: '',
      estado: 'Activo'
    };
  }

  closeForm() {
    this.showForm = false;
    this.formData = {};
  }

  saveTurno() {
    if (this.formData.id) {
      // Actualizar turno existente
      this.turnosService.updateTurno(this.formData.id, this.formData).subscribe(
        () => {
          this.getTurnos();
          this.closeForm();
        },
        (error: any) => {
          console.error('Error al actualizar turno:', error);
        }
      );
    } else {
      // Crear nuevo turno
      this.turnosService.createTurno(this.formData).subscribe(
        () => {
          this.getTurnos();
          this.closeForm();
        },
        (error: any) => {
          console.error('Error al crear turno:', error);
        }
      );
    }
  }

  deleteTurno(id: number) {
    if (confirm('¿Está seguro de eliminar este turno?')) {
      this.turnosService.deleteTurno(id).subscribe(
        () => {
          this.getTurnos();
          if (this.selectedTurno?.id === id) {
            this.selectedTurno = null;
          }
        },
        (error: any) => {
          console.error('Error al eliminar turno:', error);
        }
      );
    }
  }
}
