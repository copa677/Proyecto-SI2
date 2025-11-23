import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { PedidosService } from '../../services_back/pedidos.service';
import { PrecioService, PrecioProducto } from '../../services_back/precio.service';
import { Pedido, DetallePedido, DetallePedidoCreate, PrecioSugerido } from '../../../interface/pedidos';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-pedido-detalle',
  templateUrl: './pedido-detalle.component.html',
  styleUrls: ['./pedido-detalle.component.css']
})
export class PedidoDetalleComponent implements OnInit {
  title = 'Detalle del Pedido';
  idPedido!: number;
  pedido: Pedido | null = null;
  detalles: DetallePedido[] = [];
  detalleForm: FormGroup;
  mostrarFormulario = false;
  modoEdicion = false;
  idDetalleEdicion: number | null = null;
  cargando = false;
  guardando = false;
  precioSugerido: number | null = null;
  buscandoPrecio = false;

  productos: PrecioProducto[] = [];
  productosFiltrados: PrecioProducto[] = [];
  mostrarAutocompleteProducto = false;
  cargandoProductos = false;
  busquedaProducto: string = '';
  productoSeleccionado: PrecioProducto | null = null;

  tiposPrenda = [
    { value: 'polera', label: 'Polera' },
    { value: 'camisa', label: 'Camisa' }
  ];

  cuellos = {
    polera: ['cuello redondo', 'cuello V', 'cuello polo'],
    camisa: ['cuello con botones', 'cuello italiano', 'cuello mao']
  };

  mangas = {
    polera: ['manga corta', 'manga larga', 'sin mangas'],
    camisa: ['manga corta', 'manga larga']
  };

  materiales = ['Algodón 100%', 'Polyester', 'Popelina', 'Algodón/Polyester 50/50', 'Jersey'];
  tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  estadosBadgeClass: { [key: string]: string } = {
    'cotizacion': 'bg-yellow-100 text-yellow-800',
    'confirmado': 'bg-blue-100 text-blue-800',
    'en_produccion': 'bg-purple-100 text-purple-800',
    'completado': 'bg-green-100 text-green-800',
    'entregado': 'bg-green-100 text-green-800',
    'cancelado': 'bg-red-100 text-red-800'
  };

  estadosLabels: { [key: string]: string } = {
    'cotizacion': 'Cotización',
    'confirmado': 'Confirmado',
    'en_produccion': 'En Producción',
    'completado': 'Completado',
    'entregado': 'Entregado',
    'cancelado': 'Cancelado'
  };

  constructor(
    private fb: FormBuilder,
    private pedidosService: PedidosService,
    private precioService: PrecioService,
    private route: ActivatedRoute,
    private router: Router,
    private toastr: ToastrService
  ) {
    this.detalleForm = this.fb.group({
      id_precio: [null, Validators.required],
      tipo_prenda: ['polera', Validators.required],
      cuello: ['', Validators.required],
      manga: ['', Validators.required],
      color: ['', Validators.required],
      talla: ['', Validators.required],
      material: ['', Validators.required],
      cantidad: [1, [Validators.required, Validators.min(1)]],
      precio_unitario: [null, Validators.required]
    });
  }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      this.idPedido = +params['id'];
      this.cargarPedido();
      this.cargarDetalles();
    });
    this.cargarProductos();
  }

  cargarProductos(): void {
    this.cargandoProductos = true;
    this.precioService.listarPrecios().subscribe({
      next: (productos) => {
        this.productos = productos;
        this.productosFiltrados = productos.slice(0, 10);
        this.cargandoProductos = false;
      },
      error: (error) => {
        console.error('Error al cargar productos:', error);
        this.toastr.error('Error al cargar la lista de productos.', 'Error');
        this.cargandoProductos = false;
      }
    });
  }

  filtrarProductos(event: any): void {
    this.busquedaProducto = event.target.value;
    const valor = this.busquedaProducto.toLowerCase();
    if (valor.length > 0) {
      this.productosFiltrados = this.productos.filter(producto => {
        return producto.decripcion.toLowerCase().includes(valor) || producto.material.toLowerCase().includes(valor) || producto.talla.toLowerCase().includes(valor);
      });
      this.mostrarAutocompleteProducto = this.productosFiltrados.length > 0;
    } else {
      this.productosFiltrados = this.productos.slice(0, 10);
      this.mostrarAutocompleteProducto = true;
    }
  }

  seleccionarProducto(producto: PrecioProducto): void {
    if (!producto || !producto.id_precio) {
      this.mostrarAutocompleteProducto = false;
      this.productosFiltrados = [];
      this.productoSeleccionado = null;
      return;
    }
    // Auto-fill de todos los campos desde el producto seleccionado
    this.detalleForm.patchValue({ 
      id_precio: producto.id_precio,
      material: producto.material, 
      talla: producto.talla,
      precio_unitario: producto.precio_base
    });
    this.productoSeleccionado = producto;
    this.precioSugerido = producto.precio_base;
    this.mostrarAutocompleteProducto = false;
    this.productosFiltrados = [];
    this.busquedaProducto = '';
  }

  ocultarAutocompleteProducto(): void {
    setTimeout(() => { this.mostrarAutocompleteProducto = false; }, 200);
  }

  cargarPedido(): void {
    this.cargando = true;
    this.pedidosService.obtenerPedido(this.idPedido).subscribe({
      next: (pedido) => { this.pedido = pedido; this.cargando = false; },
      error: (error) => { console.error('Error al cargar pedido:', error); this.toastr.error('Error al cargar el pedido.', 'Error'); this.cargando = false; this.volver(); }
    });
  }

  cargarDetalles(): void {
    this.pedidosService.listarDetallesPedido(this.idPedido).subscribe({
      next: (detalles) => { this.detalles = detalles; },
      error: (error) => { console.error('Error al cargar detalles:', error); }
    });
  }

  get cuelloOptions(): string[] {
    const tipoPrenda = this.detalleForm.get('tipo_prenda')?.value;
    return tipoPrenda === 'polera' ? this.cuellos.polera : this.cuellos.camisa;
  }

  get mangaOptions(): string[] {
    const tipoPrenda = this.detalleForm.get('tipo_prenda')?.value;
    return tipoPrenda === 'polera' ? this.mangas.polera : this.mangas.camisa;
  }

  onTipoPrendaChange(): void {
    this.detalleForm.patchValue({ cuello: '', manga: '' });
    this.precioSugerido = null;
  }

  agregarDetalle(): void {
    if (this.detalleForm.invalid) {
      this.toastr.warning('Por favor complete todos los campos requeridos.', 'Formulario incompleto');
      return;
    }
    this.guardando = true;
    const detalleCreate: DetallePedidoCreate = { id_pedido: this.idPedido, ...this.detalleForm.value };
    if (this.modoEdicion && this.idDetalleEdicion) {
      this.pedidosService.actualizarDetallePedido(this.idDetalleEdicion, this.detalleForm.value).subscribe({
        next: () => { this.toastr.success('Producto actualizado correctamente.', 'Éxito'); this.cargarDetalles(); this.cargarPedido(); this.cancelarEdicion(); this.guardando = false; },
        error: (error) => { console.error('Error al actualizar detalle:', error); this.toastr.error('Error al actualizar el producto.', 'Error'); this.guardando = false; }
      });
    } else {
      this.pedidosService.crearDetallePedido(detalleCreate).subscribe({
        next: (detalle) => { 
          this.toastr.success(`Producto agregado: ${detalle.tipo_prenda} - ${detalle.color} (${detalle.cantidad} unidades)`, 'Éxito'); 
          this.cargarDetalles(); 
          this.cargarPedido(); 
          this.cancelarEdicion(); 
          this.guardando = false; 
        },
        error: (error) => { 
          console.error('Error al agregar producto:', error); 
          this.toastr.error('Error al agregar el producto.', 'Error'); 
          this.guardando = false; 
        }
      });
    }
  }

  editarDetalle(detalle: DetallePedido): void {
    this.modoEdicion = true;
    this.idDetalleEdicion = detalle.id_detalle;
    this.mostrarFormulario = true;
    this.precioSugerido = parseFloat(detalle.precio_unitario) || null;
    this.detalleForm.patchValue({ tipo_prenda: detalle.tipo_prenda, cuello: detalle.cuello, manga: detalle.manga, color: detalle.color, talla: detalle.talla, material: detalle.material, cantidad: detalle.cantidad });
  }

  eliminarDetalle(detalle: DetallePedido): void {
    if (confirm(`¿Está seguro de eliminar este producto?\n${detalle.tipo_prenda} - ${detalle.color} - Talla ${detalle.talla}\nCantidad: ${detalle.cantidad}`)) {
      this.pedidosService.eliminarDetallePedido(detalle.id_detalle).subscribe({
        next: () => { 
          this.toastr.success('Producto eliminado correctamente.', 'Éxito'); 
          this.cargarDetalles(); 
          this.cargarPedido(); 
        },
        error: (error) => { 
          console.error('Error al eliminar producto:', error); 
          this.toastr.error('Error al eliminar el producto.', 'Error'); 
        }
      });
    }
  }

  cancelarEdicion(): void {
    this.modoEdicion = false;
    this.idDetalleEdicion = null;
    this.mostrarFormulario = false;
    this.detalleForm.reset({ tipo_prenda: 'polera', cantidad: 1 });
    this.precioSugerido = null;
  }

  abrirFormulario(): void {
    this.modoEdicion = false;
    this.mostrarFormulario = true;
    this.detalleForm.reset({ tipo_prenda: 'polera', cantidad: 1 });
  }

  volver(): void {
    this.router.navigate(['/menu/pedidos']);
  }

  getEstadoBadgeClass(estado: string): string {
    return this.estadosBadgeClass[estado] || 'bg-gray-100 text-gray-800';
  }

  getEstadoLabel(estado: string): string {
    return this.estadosLabels[estado] || estado;
  }
}
