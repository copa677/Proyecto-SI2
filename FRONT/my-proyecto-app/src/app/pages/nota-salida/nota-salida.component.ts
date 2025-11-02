import { Component, OnInit } from '@angular/core';
import { NotaSalidaService } from '../../services_back/nota-salida.service';
import { InventarioService } from '../../services_back/inventario.service';
import { PersonalService } from '../../services_back/personal.service';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-nota-salida',
  templateUrl: './nota-salida.component.html',
  styleUrls: ['./nota-salida.component.css']
})
export class NotaSalidaComponent implements OnInit {
  notasSalida: any[] = [];
  detalles: any[] = [];
  notaSeleccionada: any = null;
  modalVisible: boolean = false;
  showForm: boolean = false;
  formData: any = {
    fecha_salida: '',
    motivo: '',
    id_personal: '',
    area: '',
    detalles: []
  };
  personal: any[] = [];
  inventario: any[] = [];

  constructor(
    private notaSalidaService: NotaSalidaService,
    private inventarioService: InventarioService,
    private personalService: PersonalService,
    private toastr: ToastrService
  ) {}

  ngOnInit(): void {
    this.cargarNotasSalida();
    this.cargarPersonal();
    this.cargarInventario();
  }

  cargarNotasSalida() {
    this.notaSalidaService.getNotasSalida().subscribe({
      next: (data: any) => {
        // Si las notas no traen solicitante/área, inicializar como N/A
        this.notasSalida = (data || []).map((nota: any) => ({
          ...nota,
          solicitante: nota.solicitante || 'N/A',
          area: nota.area || 'N/A'
        }));
      },
      error: (error: any) => {
        console.error('Error al cargar notas de salida:', error);
        this.toastr.error('No se pudieron cargar las notas de salida', 'Error');
      }
    });
  }

  cargarPersonal() {
    this.personalService.getPersonales().subscribe({
      next: (data: any) => {
        this.personal = data;
      },
      error: (error: any) => {
        console.error('Error al cargar personal:', error);
        this.toastr.error('No se pudo cargar el personal', 'Error');
      }
    });
  }

  cargarInventario() {
    this.inventarioService.getInventarios().subscribe({
      next: (data: any) => {
        this.inventario = data;
      },
      error: (error: any) => {
        console.error('Error al cargar inventario:', error);
        this.toastr.error('No se pudo cargar el inventario', 'Error');
      }
    });
  }

  seleccionarNota(nota: any) {
    this.notaSalidaService.getDetallesSalida(nota.id_salida).subscribe({
      next: (data: any) => {
        this.notaSeleccionada = {
          ...nota,
          fecha_salida: data.fecha,
          motivo: data.motivo,
          solicitante: data.solicitante,
          area: data.area,
          estado: data.estado
        };
        this.detalles = data.detalles || [];
        this.modalVisible = true;
      },
      error: (error: any) => {
        console.error('Error al cargar detalles:', error);
        this.toastr.error('No se pudieron cargar los detalles de la nota', 'Error');
        this.detalles = [];
        this.modalVisible = true;
      }
    });
  }

  openForm() {
    this.formData = {
      fecha_salida: new Date().toISOString().slice(0, 10), // YYYY-MM-DD
      motivo: '',
      id_personal: this.personal.length > 0 ? this.personal[0].id_personal : '',
      area: '',
      detalles: [{ id_inventario: '', cantidad: 1 }]
    };
    this.showForm = true;
  }

  closeForm() {
    this.showForm = false;
  }

  addDetalle() {
    this.formData.detalles.push({ id_inventario: '', cantidad: 1 });
  }

  removeDetalle(index: number) {
    this.formData.detalles.splice(index, 1);
  }

  getLote(id_inventario: any): string {
    const item = this.inventario.find(i => i.id_inventario === +id_inventario);
    return item ? item.id_lote.toString() : 'N/A';
  }

  saveNotaSalida() {
    // Validar campos requeridos antes de enviar
    if (!this.formData.fecha_salida) {
      this.toastr.warning('La fecha de salida es obligatoria', 'Atención');
      return;
    }
    if (!this.formData.motivo) {
      this.toastr.warning('El motivo es obligatorio', 'Atención');
      return;
    }
    if (!this.formData.id_personal) {
      this.toastr.warning('Debe seleccionar un responsable', 'Atención');
      return;
    }
    if (!this.formData.area) {
      this.toastr.warning('El área es obligatoria', 'Atención');
      return;
    }
    if (!this.formData.detalles || this.formData.detalles.length === 0) {
      this.toastr.warning('Debe agregar al menos un detalle', 'Atención');
      return;
    }
    // Filtrar detalles válidos
    const detallesValidos = this.formData.detalles.filter((d: any) => d.id_inventario && d.cantidad > 0);
    if (detallesValidos.length === 0) {
      this.toastr.warning('Debe agregar al menos un detalle válido', 'Atención');
      return;
    }
    const data = {
      fecha_salida: this.formData.fecha_salida,
      motivo: this.formData.motivo,
      id_personal: this.formData.id_personal,
      area: this.formData.area,
      detalles: detallesValidos
    };
    this.notaSalidaService.createNotaSalida(data).subscribe({
      next: () => {
        this.toastr.success('Nota de salida creada correctamente', 'Éxito');
        this.cargarNotasSalida();
        this.closeForm();
      },
      error: (error: any) => {
        console.error('Error al crear nota de salida:', error);
        this.toastr.error('Error al crear la nota de salida', 'Error');
      }
    });
  }
}
