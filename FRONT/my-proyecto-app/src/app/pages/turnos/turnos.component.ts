import { Component, OnInit } from '@angular/core';
import { TurnosService } from '../../services_back/turnos.service';
import { Turno } from '../../../interface/turno';
import { ToastrService } from 'ngx-toastr';

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

  constructor(private turnosService: TurnosService, private toastr: ToastrService) { }

  ngOnInit(): void {
    this.getTurnos();
  }

  getTurnos() {
    this.turnosService.getTurnos().subscribe({
      next: (data) => (this.turnos = data),
      error: () => this.toastr.error('No se pudieron cargar los turnos', 'Error')
    });
  }

  openForm(turno?: Turno) {
    this.showForm = true;
    this.formData = turno
      ? { ...turno }
      : { turno: '', hora_entrada: '', hora_salida: '', estado: 'activo' };
  }

  closeForm() {
    this.showForm = false;
    this.formData = {};
  }

  saveTurno() {
    const payload = {
      ...this.formData,
      estado: (this.formData.estado || 'activo').toString().toLowerCase()
    };

    if (this.formData.id) {
      this.turnosService.updateTurno(this.formData.id, payload).subscribe({
        next: () => {
          this.toastr.success('Turno actualizado correctamente', 'Éxito');
          this.getTurnos();
          this.closeForm();
        },
        error: () => this.toastr.error('Error al actualizar el turno', 'Error')
      });
    } else {
      this.turnosService.createTurno(payload).subscribe({
        next: () => {
          this.toastr.success('Turno creado correctamente', 'Éxito');
          this.getTurnos();
          this.closeForm();
        },
        error: () => this.toastr.error('Error al crear el turno', 'Error')
      });
    }
  }


  deleteTurno(id: number) {
    if (!confirm('¿Desea eliminar este turno?')) return;
    this.turnosService.deleteTurno(id).subscribe({
      next: () => {
        this.toastr.success('Turno eliminado correctamente', 'Éxito');
        this.getTurnos();
      },
      error: () => this.toastr.error('Error al eliminar el turno', 'Error')
    });
  }
}
