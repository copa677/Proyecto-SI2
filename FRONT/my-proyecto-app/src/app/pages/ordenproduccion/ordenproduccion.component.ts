import { Component, OnInit } from '@angular/core';
import { ToastrService } from 'ngx-toastr';
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
    responsable: '',
    materias_primas: []
  };
  
  inventario: any[] = [];
  personal: any[] = [];
  trazabilidad: any[] = [];

  productosModelo = ['Camisa', 'Polera', 'Camiseta'];
  colores = ['Blanco', 'Negro', 'Azul', 'Rojo', 'Verde', 'Amarillo', 'Gris'];
  tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  constructor(
    private ordenService: OrdenProduccionService,
    private inventarioService: InventarioService,
    private personalService: PersonalService,
    private toastr: ToastrService
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
        this.toastr.error('No se pudieron cargar las órdenes de producción', 'Error');
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
        this.toastr.error('No se pudo cargar el inventario', 'Error');
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
        this.toastr.error('No se pudo cargar el personal', 'Error');
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
      responsable: this.personal.length > 0 ? this.personal[0].id : '',
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
    if (!this.formData.cod_orden || !this.formData.producto_modelo) {
      this.toastr.warning('Complete los campos obligatorios', 'Atención');
      return;
    }

    if (!this.formData.responsable) {
      this.toastr.warning('Debe seleccionar un responsable', 'Atención');
      return;
    }

    if (!this.formData.fecha_inicio) {
      this.toastr.warning('Debe especificar la fecha de inicio', 'Atención');
      return;
    }

    if (!this.formData.materias_primas || this.formData.materias_primas.length === 0) {
      this.toastr.warning('Debe agregar al menos una materia prima', 'Atención');
      return;
    }

    const materiasValidas = this.formData.materias_primas
      .filter((m: any) => m.id_inventario && m.cantidad > 0)
      .map((m: any) => ({
        id_inventario: parseInt(m.id_inventario),
        cantidad: parseFloat(m.cantidad)
      }));

    if (materiasValidas.length === 0) {
      this.toastr.warning('Debe agregar al menos una materia prima válida', 'Atención');
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
      id_personal: parseInt(this.formData.responsable),
      materias_primas: materiasValidas
    };

    this.ordenService.createOrdenConMaterias(ordenData).subscribe({
      next: (response) => {
        this.toastr.success(`Orden creada exitosamente. Nota de salida N° ${response.id_nota_salida} generada automáticamente.`, 'Éxito');
        this.cargarOrdenes();
        this.closeForm();
      },
      error: (error) => {
        console.error('Error al crear orden:', error);
        this.toastr.error(error.error?.error || 'Error al crear orden', 'Error');
      }
    });
  }

  deleteOrden(id: number) {
    if (confirm('¿Está seguro de eliminar esta orden?')) {
      this.ordenService.deleteOrden(id).subscribe({
        next: () => {
          this.toastr.success('Orden eliminada correctamente', 'Éxito');
          this.cargarOrdenes();
        },
        error: (error) => {
          console.error('Error al eliminar orden:', error);
          this.toastr.error('Error al eliminar la orden', 'Error');
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
        this.toastr.info('Trazabilidad cargada correctamente', 'Información');
      },
      error: (error) => {
        console.error('Error al cargar trazabilidad:', error);
        this.trazabilidad = [];
        this.showTrazabilidadModal = true;
        this.toastr.error('Error al cargar trazabilidad', 'Error');
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
