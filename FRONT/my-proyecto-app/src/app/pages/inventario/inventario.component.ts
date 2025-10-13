import { Component, OnInit } from '@angular/core';
import { InventarioService } from '../../services_back/inventario.service';
import { Inventario } from '../../../interface/inventario';

@Component({
  selector: 'app-inventario',
  templateUrl: './inventario.component.html',
  styleUrls: ['./inventario.component.css']
})
export class InventarioComponent implements OnInit {
  inventarios: Inventario[] = [];
  selectedInventario: Inventario | null = null;
  showForm = false;
  formData: Partial<Inventario> = {};
  searchTerm = '';
  modalVisible = false;
  trazabilidad: any[] = [];

  constructor(private inventarioService: InventarioService) {}

  ngOnInit(): void {
    this.getInventarios();
  }

  getInventarios() {
    this.inventarioService.getInventarios().subscribe(
      (data: Inventario[]) => {
        this.inventarios = data;
      },
      error => {
        console.error('Error al obtener inventarios:', error);
      }
    );
  }

  get filteredInventarios() {
    if (!this.searchTerm) return this.inventarios;
    return this.inventarios.filter(inv => 
      inv.nombre_materia_prima?.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
      inv.unidad_medida?.toLowerCase().includes(this.searchTerm.toLowerCase())
    );
  }

  selectInventario(inventario: Inventario) {
    this.selectedInventario = inventario;
    this.showForm = false;
  }

  openForm(inventario?: Inventario) {
    this.showForm = true;
    this.formData = inventario ? { ...inventario } : {
      nombre_materia_prima: '',
      cantidad_actual: '',
      unidad_medida: '',
      ubicacion: '',
      estado: 'Activo',
      fecha_actualizacion: '',
      id_lote: 0
    };
  }

  closeForm() {
    this.showForm = false;
    this.formData = {};
    }

    verTrazabilidad(inventario: Inventario) {
      // Llama al servicio para obtener la trazabilidad del lote
      this.inventarioService.getTrazabilidadPorLote(inventario.id_lote).subscribe(
        (data: any[]) => {
          this.trazabilidad = data;
          this.modalVisible = true;
        },
        error => {
          this.trazabilidad = [];
          this.modalVisible = true;
        }
      );
    }

  saveInventario() {
    if (this.formData.id_inventario) {
      // Actualizar inventario existente
      this.inventarioService.updateInventario(this.formData.id_inventario, this.formData).subscribe(
        () => {
          this.getInventarios();
          this.closeForm();
        },
        error => {
          console.error('Error al actualizar inventario:', error);
        }
      );
    } else {
      // Crear nuevo inventario
      this.inventarioService.createInventario(this.formData).subscribe(
        () => {
          this.getInventarios();
          this.closeForm();
        },
        error => {
          console.error('Error al crear inventario:', error);
        }
      );
    }
  }

  deleteInventario(id: number) {
    if (confirm('¿Está seguro de eliminar este item del inventario?')) {
      this.inventarioService.deleteInventario(id).subscribe(
        () => {
          this.getInventarios();
          if (this.selectedInventario?.id_inventario === id) {
            this.selectedInventario = null;
          }
        },
        error => {
          console.error('Error al eliminar inventario:', error);
        }
      );
    }
  }

  getEstadoClass(estado: string): string {
    switch(estado) {
      case 'Disponible': return 'bg-green-100 text-green-800';
      case 'Stock Bajo': return 'bg-yellow-100 text-yellow-800';
      case 'Agotado': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  }
}
