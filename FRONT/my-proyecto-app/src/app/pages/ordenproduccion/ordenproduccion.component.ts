import { Component, OnInit } from '@angular/core';
import { TrazabilidadService } from '../../services_back/trazabilidad.service';

@Component({
  selector: 'app-ordenproduccion',
  templateUrl: './ordenproduccion.component.html',
  styleUrls: ['./ordenproduccion.component.css']
})
export class OrdenProduccionComponent implements OnInit {
  ordenes = [
    {
      id_orden: 1,
      codigo_orden: 'OP-001',
      fecha: '2025-10-01',
      producto: 'Pan Integral',
      cantidad: 500,
      estado: 'En Proceso'
    },
    {
      id_orden: 2,
      codigo_orden: 'OP-002',
      fecha: '2025-10-03',
      producto: 'Galletas',
      cantidad: 300,
      estado: 'Finalizada'
    },
    {
      id_orden: 3,
      codigo_orden: 'OP-003',
      fecha: '2025-10-05',
      producto: 'Bizcocho',
      cantidad: 200,
      estado: 'Pendiente'
    }
  ];
  showForm = false;
  formData: any = {};
  trazabilidad: any[] = [];
  modalVisible = false;

  constructor(private trazabilidadService: TrazabilidadService) {}
  verTrazabilidad(orden: any) {
    // Aquí deberías obtener el id relacionado para la trazabilidad de la orden
    // Por ejemplo, si la orden tiene un id_lote o id_trazabilidad relacionado
    // Aquí se usa id_orden como ejemplo, ajusta según tu modelo real
    this.trazabilidadService.getTrazabilidad(orden.id_orden).subscribe(
      (data: any) => {
        this.trazabilidad = Array.isArray(data) ? data : (data ? [data] : []);
        this.modalVisible = true;
      },
      (error: any) => {
        this.trazabilidad = [];
        this.modalVisible = true;
      }
    );
  }

  openForm(orden?: any) {
    this.showForm = true;
    this.formData = orden ? { ...orden } : {};
  }

  saveOrden() {
    if (this.formData.id_orden) {
      // Editar orden existente
      const idx = this.ordenes.findIndex(o => o.id_orden === this.formData.id_orden);
      if (idx > -1) this.ordenes[idx] = { ...this.formData };
    } else {
      // Crear nueva orden
      const newId = Math.max(...this.ordenes.map(o => o.id_orden), 0) + 1;
      this.ordenes.push({ ...this.formData, id_orden: newId });
    }
    this.showForm = false;
    this.formData = {};
  }

  deleteOrden(id: number): void {
    if (confirm('¿Está seguro de eliminar esta orden?')) {
      this.ordenes = this.ordenes.filter((o: any) => o.id_orden !== id);
    }
  }

  ngOnInit(): void {
    // Módulo pendiente de implementación en el backend
  }
}
