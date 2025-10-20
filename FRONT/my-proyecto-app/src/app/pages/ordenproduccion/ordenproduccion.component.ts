import { Component, OnInit } from '@angular/core';
import { OrdenProduccionService, OrdenProduccion, CrearOrdenConMaterias } from '../../services_back/ordenproduccion.service';
import { InventarioService } from '../../services_back/inventario.service';
import { PersonalService } from '../../services_back/personal.service';

@Component({
  selector: 'app-ordenproduccion',
  templateUrl: './ordenproduccion.component.html',
  styleUrls: ['./ordenproduccion.component.css']
})
export class OrdenProduccionComponent implements OnInit {
  ordenes: OrdenProduccion[] = [];
  showForm = false;
  showTrazabilidadModal = false;
  formData: any = {
    cod_orden: '',
    fecha_inicio: '',
    fecha_fin: '',
    fecha_entrega: '',
    producto_modelo: '',
    color: '',
    talla: '',
    cantidad_total: 0,
    id_personal: '',
    materias_primas: []
  };
  
  // Catálogos
  inventario: any[] = [];
  personal: any[] = [];
  trazabilidad: any[] = [];
  
  // Opciones de productos
  productosModelo = ['Camisa', 'Polera', 'Camiseta'];
  colores = ['Blanco', 'Negro', 'Azul', 'Rojo', 'Verde', 'Amarillo', 'Gris'];
  tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  constructor(
    private ordenService: OrdenProduccionService,
    private inventarioService: InventarioService,
    private personalService: PersonalService
  ) {}

  ngOnInit(): void {
    this.cargarOrdenes();
    this.cargarInventario();
    this.cargarPersonal();
  }

  cargarOrdenes() {
    this.ordenService.getOrdenes().subscribe({
      next: (data) => {
        this.ordenes = data;
      },
      error: (error) => {
        console.error('Error al cargar órdenes:', error);
      }
    });
  }

  cargarInventario() {
    this.inventarioService.getInventarios().subscribe({
      next: (data) => {
        this.inventario = data;
      },
      error: (error) => {
        console.error('Error al cargar inventario:', error);
      }
    });
  }

  cargarPersonal() {
    this.personalService.getPersonales().subscribe({
      next: (data) => {
        this.personal = data;
      },
      error: (error) => {
        console.error('Error al cargar personal:', error);
      }
    });
  }

  openForm() {
    this.formData = {
      cod_orden: this.generarCodigoOrden(),
      fecha_inicio: new Date().toISOString().slice(0, 10),
      fecha_fin: '',
      fecha_entrega: '',
      producto_modelo: 'Camisa',
      color: 'Blanco',
      talla: 'M',
      cantidad_total: 1,
      id_personal: this.personal.length > 0 ? this.personal[0].id_personal : '',
      materias_primas: [{ id_inventario: '', cantidad: 0 }]
    };
    this.showForm = true;
  }

  closeForm() {
    this.showForm = false;
  }

  generarCodigoOrden(): string {
    const fecha = new Date();
    const year = fecha.getFullYear();
    const month = String(fecha.getMonth() + 1).padStart(2, '0');
    const day = String(fecha.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `OP${year}${month}${day}-${random}`;
  }

  addMateriaPrima() {
    this.formData.materias_primas.push({ id_inventario: '', cantidad: 0 });
  }

  removeMateriaPrima(index: number) {
    this.formData.materias_primas.splice(index, 1);
  }

  saveOrden() {
    // Validaciones
    if (!this.formData.cod_orden || !this.formData.producto_modelo) {
      alert('Complete los campos obligatorios.');
      return;
    }

    if (!this.formData.id_personal) {
      alert('Debe seleccionar un responsable.');
      return;
    }

    if (!this.formData.fecha_inicio) {
      alert('Debe especificar la fecha de inicio.');
      return;
    }

    if (!this.formData.materias_primas || this.formData.materias_primas.length === 0) {
      alert('Debe agregar al menos una materia prima.');
      return;
    }

    // Filtrar materias primas válidas y convertir a números
    const materiasValidas = this.formData.materias_primas
      .filter((m: any) => m.id_inventario && m.cantidad > 0)
      .map((m: any) => ({
        id_inventario: parseInt(m.id_inventario),
        cantidad: parseFloat(m.cantidad)
      }));

    if (materiasValidas.length === 0) {
      alert('Debe agregar al menos una materia prima válida.');
      return;
    }

    const ordenData: CrearOrdenConMaterias = {
      cod_orden: this.formData.cod_orden,
      fecha_inicio: this.formData.fecha_inicio,
      fecha_fin: this.formData.fecha_fin || this.formData.fecha_inicio,
      fecha_entrega: this.formData.fecha_entrega || this.formData.fecha_inicio,
      producto_modelo: this.formData.producto_modelo,
      color: this.formData.color,
      talla: this.formData.talla,
      cantidad_total: parseInt(this.formData.cantidad_total),
      id_personal: parseInt(this.formData.id_personal),
      materias_primas: materiasValidas
    };

    console.log('Datos a enviar:', ordenData);

    this.ordenService.createOrdenConMaterias(ordenData).subscribe({
      next: (response) => {
        console.log('Orden creada:', response);
        alert(`Orden creada exitosamente. Nota de salida N° ${response.id_nota_salida} generada automáticamente.`);
        this.cargarOrdenes();
        this.closeForm();
      },
      error: (error) => {
        console.error('Error al crear orden:', error);
        console.error('Detalles del error:', error.error);
        alert('Error al crear orden: ' + (error.error?.error || JSON.stringify(error.error) || 'Error desconocido'));
      }
    });
  }

  deleteOrden(id: number) {
    if (confirm('¿Está seguro de eliminar esta orden?')) {
      this.ordenService.deleteOrden(id).subscribe({
        next: () => {
          this.cargarOrdenes();
        },
        error: (error) => {
          console.error('Error al eliminar orden:', error);
        }
      });
    }
  }

  verTrazabilidad(orden: OrdenProduccion) {
    if (!orden.id_orden) return;
    
    this.ordenService.getTrazabilidad(orden.id_orden).subscribe({
      next: (data) => {
        this.trazabilidad = data.trazabilidades || [];
        this.showTrazabilidadModal = true;
      },
      error: (error) => {
        console.error('Error al cargar trazabilidad:', error);
        this.trazabilidad = [];
        this.showTrazabilidadModal = true;
      }
    });
  }

  closeTrazabilidadModal() {
    this.showTrazabilidadModal = false;
  }

  getEstadoClass(estado: string): string {
    switch (estado) {
      case 'En Proceso': return 'bg-blue-100 text-blue-800';
      case 'Completada': return 'bg-green-100 text-green-800';
      case 'Pendiente': return 'bg-yellow-100 text-yellow-800';
      case 'Cancelada': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  }

  getNombreMateria(id: number): string {
    const item = this.inventario.find(i => i.id_inventario === id);
    return item ? item.nombre_materia_prima : 'N/A';
  }

  getStockDisponible(id: number): number {
    const item = this.inventario.find(i => i.id_inventario === id);
    return item ? item.cantidad_actual : 0;
  }
}
