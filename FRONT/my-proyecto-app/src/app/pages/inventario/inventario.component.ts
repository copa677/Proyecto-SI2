import { Component, OnInit } from '@angular/core';
import { InventarioService } from '../../services_back/inventario.service';
import { Inventario } from '../../inventario.interface';

@Component({
  selector: 'app-inventario',
  templateUrl: './inventario.component.html',
  styleUrls: ['./inventario.component.css']
})
export class InventarioComponent implements OnInit {
  inventarios: Inventario[] = [];
  selectedInventario: Inventario | null = null;
  showForm = false;
  formData: Partial<Inventario> = {
    id_inventario: undefined,
    nombre_materia_prima: '',
    cantidad_actual: undefined,
    unidad_medida: '',
    ubicacion: '',
    estado: '',
    fecha_actualizacion: '',
    id_lote: undefined
  };
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
    if (inventario) {
      // Asegurarse que cantidad_actual sea number
      let cantidad: number | undefined = undefined;
      if (typeof inventario.cantidad_actual === 'string') {
        cantidad = parseFloat((inventario.cantidad_actual as string).replace(',', '.'));
      } else if (typeof inventario.cantidad_actual === 'number') {
        cantidad = inventario.cantidad_actual;
      }
      this.formData = { ...inventario, cantidad_actual: cantidad };
    } else {
      this.formData = {
        nombre_materia_prima: '',
        cantidad_actual: undefined,
        unidad_medida: '',
        ubicacion: '',
        estado: 'Activo',
        fecha_actualizacion: '',
        id_lote: undefined
      };
    }
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
    console.log('saveInventario llamado');
    console.log('formData antes de procesar:', this.formData);
    
    // Asegurar que cantidad_actual sea número y no string con coma
    // Normalizar cantidad_actual para que siempre sea number o undefined
    if (typeof this.formData.cantidad_actual === 'string') {
      const normalizado = (this.formData.cantidad_actual as string).replace(',', '.');
      this.formData.cantidad_actual = normalizado === '' ? undefined : parseFloat(normalizado);
    }
    
    console.log('formData después de normalizar:', this.formData);
    
    if (this.formData.id_inventario) {
      // Actualizar inventario existente
      const data: Partial<Inventario> = { ...this.formData };
      console.log('Actualizando inventario con ID:', this.formData.id_inventario);
      console.log('Datos a enviar:', data);
      
      this.inventarioService.updateInventario(this.formData.id_inventario, data).subscribe(
        (response) => {
          console.log('Inventario actualizado exitosamente:', response);
          this.getInventarios();
          this.closeForm();
        },
        error => {
          console.error('Error al actualizar inventario:', error);
          alert('Error al actualizar inventario. Revisa la consola para más detalles.');
        }
      );
    } else {
      // Crear nuevo inventario
      const data: Partial<Inventario> = { ...this.formData };
      console.log('Creando nuevo inventario');
      console.log('Datos a enviar:', data);
      
      this.inventarioService.createInventario(data).subscribe(
        (response) => {
          console.log('Inventario creado exitosamente:', response);
          this.getInventarios();
          this.closeForm();
        },
        error => {
          console.error('Error al crear inventario:', error);
          console.error('Detalles del error:', error.error);
          alert('Error al crear inventario. Revisa la consola para más detalles.');
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
