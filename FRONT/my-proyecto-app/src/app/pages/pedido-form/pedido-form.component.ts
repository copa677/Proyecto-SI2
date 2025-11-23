import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { PedidosService } from '../../services_back/pedidos.service';
import { ClienteService, ClienteApiResponse } from '../../services_back/cliente.service';
import { PrecioService, PrecioProducto } from '../../services_back/precio.service';
import { Pedido, PedidoCreate, PedidoUpdate, DetallePedidoCreate } from '../../../interface/pedidos';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-pedido-form',
  templateUrl: './pedido-form.component.html',
  styleUrls: ['./pedido-form.component.css']
})
export class PedidoFormComponent implements OnInit {
  // Guarda el último producto seleccionado
  private productoSeleccionado: PrecioProducto | null = null;
  title = 'Crear Pedido';
  pedidoForm: FormGroup;
  detalleForm: FormGroup;
  idPedido: number | null = null;
  pedidoActual: Pedido | null = null;
  modoEdicion = false;
  cargando = false;
  guardando = false;

  // Lista de productos agregados
  productosAgregados: any[] = [];
  totalPedido = 0;

  // Para el formulario de productos
  precioSugerido: number | null = null;
  buscandoPrecio = false;
  busquedaProducto: string = '';

  // --- Autocompletado de clientes ---
  clientes: ClienteApiResponse[] = [];
  clientesFiltrados: ClienteApiResponse[] = [];
  mostrarAutocompleteCliente = false;
  cargandoClientes = false;

  // --- Autocompletado de colores ---
  coloresComunes: string[] = [
    'Blanco', 'Negro', 'Azul', 'Rojo', 'Verde', 'Amarillo', 'Gris', 'Celeste', 'Naranja', 'Marrón',
    'Beige', 'Violeta', 'Rosado', 'Turquesa', 'Bordó', 'Fucsia', 'Lila', 'Coral', 'Dorado', 'Plateado',
    'Verde Lima', 'Azul Marino', 'Mostaza'
  ];
  coloresFiltrados: string[] = [];
  mostrarAutocompleteColor = false;

  // --- Autocompletado de productos desde precios ---
  productos: PrecioProducto[] = [];
  productosFiltrados: PrecioProducto[] = [];
  mostrarAutocompleteProducto = false;
  cargandoProductos = false;

  estados = [
    { value: 'cotizacion', label: 'Cotización' },
    { value: 'confirmado', label: 'Confirmado' },
    { value: 'en_produccion', label: 'En Producción' },
    { value: 'completado', label: 'Completado' },
    { value: 'entregado', label: 'Entregado' }
  ];

  constructor(
    private fb: FormBuilder,
    private pedidosService: PedidosService,
    private clienteService: ClienteService,
    private precioService: PrecioService,
    private route: ActivatedRoute,
    private router: Router,
    private toastr: ToastrService
  ) {
    this.pedidoForm = this.fb.group({
      fecha_entrega_prometida: ['', Validators.required],
      estado: ['cotizacion', Validators.required],
      id_cliente: ['', [Validators.required, Validators.min(1)]],
      observaciones: ['']
    });

    // Formulario completo según la base de datos
    this.detalleForm = this.fb.group({
      id_precio: [null, Validators.required], // Producto seleccionado de la tabla precios
      descripcion: ['', Validators.required],  // Auto-fill desde producto
      material: ['', Validators.required],     // Auto-fill desde producto
      talla: ['', Validators.required],        // Auto-fill desde producto
      tipo_prenda: ['', Validators.required],  // Campo requerido por BD
      cuello: ['', Validators.required],       // Campo requerido por BD
      manga: ['', Validators.required],        // Campo requerido por BD
      color: ['', Validators.required],        // Campo manual obligatorio
      cantidad: [1, [Validators.required, Validators.min(1)]],
      precio_unitario: [0, Validators.required] // Auto-fill desde producto
    });
  }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      if (params['id']) {
        this.idPedido = +params['id'];
        this.modoEdicion = true;
        this.title = 'Editar Pedido';
        this.cargarPedido();
      }
    });

    // Cargar clientes desde la base de datos
    this.cargarClientes();
    
    // Cargar productos/precios desde la base de datos
    this.cargarProductos();
  }

  cargarClientes(): void {
    this.cargandoClientes = true;
    this.clienteService.getClientes().subscribe({
      next: (clientes) => {
        this.clientes = clientes;
        this.clientesFiltrados = clientes.slice(0, 10);
        this.cargandoClientes = false;
      },
      error: (error) => {
        console.error('Error al cargar clientes:', error);
        this.toastr.error('Error al cargar la lista de clientes.', 'Error');
        this.cargandoClientes = false;
      }
    });
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

  // --- Métodos de autocompletado de clientes ---
  filtrarClientes(event: any): void {
    const valor = event.target.value.toLowerCase();
    if (valor.length > 0) {
      this.clientesFiltrados = this.clientes.filter(cliente =>
        cliente.nombre_completo.toLowerCase().includes(valor) ||
        cliente.telefono.includes(valor) ||
        cliente.id.toString().includes(valor)
      );
      this.mostrarAutocompleteCliente = this.clientesFiltrados.length > 0;
    } else {
      this.clientesFiltrados = this.clientes.slice(0, 10);
      this.mostrarAutocompleteCliente = this.clientesFiltrados.length > 0;
    }
  }

  seleccionarCliente(cliente: ClienteApiResponse): void {
    this.pedidoForm.patchValue({ id_cliente: cliente.id });
    this.mostrarAutocompleteCliente = false;
    this.clientesFiltrados = [];
  }

  ocultarAutocompleteCliente(): void {
    setTimeout(() => {
      this.mostrarAutocompleteCliente = false;
    }, 200);
  }

  mostrarTodosClientes(): void {
    this.clientesFiltrados = this.clientes.slice(0, 10);
    this.mostrarAutocompleteCliente = true;
  }

  // --- Métodos de autocompletado de colores ---
  filtrarColores(event: any): void {
    const valor = event.target.value.toLowerCase();
    if (valor.length > 0) {
      this.coloresFiltrados = this.coloresComunes.filter(color =>
        color.toLowerCase().includes(valor)
      );
      this.mostrarAutocompleteColor = this.coloresFiltrados.length > 0;
    } else {
      this.coloresFiltrados = [];
      this.mostrarAutocompleteColor = false;
    }
  }

  seleccionarColor(color: string): void {
    this.detalleForm.patchValue({ color: color });
    this.mostrarAutocompleteColor = false;
    this.coloresFiltrados = [];
  }

  ocultarAutocompleteColor(): void {
    setTimeout(() => {
      this.mostrarAutocompleteColor = false;
    }, 200);
  }

  // --- Métodos de autocompletado de productos ---
  filtrarProductos(event: any): void {
    this.busquedaProducto = event.target.value;
    const valor = this.busquedaProducto.toLowerCase();
    if (valor.length > 0) {
      this.productosFiltrados = this.productos.filter(producto => {
        return producto.decripcion.toLowerCase().includes(valor) ||
               producto.material.toLowerCase().includes(valor) ||
               producto.talla.toLowerCase().includes(valor);
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

    // Llenar el formulario con los datos del producto seleccionado
    this.detalleForm.patchValue({
      id_precio: producto.id_precio,
      descripcion: producto.decripcion,
      material: producto.material,
      talla: producto.talla,
      precio_unitario: producto.precio_base
    });

    this.precioSugerido = producto.precio_base;
    this.mostrarAutocompleteProducto = false;
    this.productosFiltrados = [];
    this.busquedaProducto = '';
    this.productoSeleccionado = producto;
  this.toastr.success(`Producto seleccionado: ${producto.decripcion}`, 'Éxito');
  }

  ocultarAutocompleteProducto(): void {
    setTimeout(() => {
      this.mostrarAutocompleteProducto = false;
      // Si el usuario no seleccionó un producto válido, limpiar los campos dependientes
      if (!this.productoSeleccionado || !this.productoSeleccionado.id_precio) {
        this.detalleForm.patchValue({
          id_precio: null,
          descripcion: '',
          material: '',
          talla: '',
          precio_unitario: 0
        });
      }
    }, 200);
  }

  mostrarTodosProductos(): void {
    this.productosFiltrados = this.productos.slice(0, 15);
    this.mostrarAutocompleteProducto = true;
  }

  cargarPedido(): void {
    if (!this.idPedido) return;

    this.cargando = true;
    this.pedidosService.obtenerPedido(this.idPedido).subscribe({
      next: (pedido) => {
        this.pedidoActual = pedido;
        this.pedidoForm.patchValue({
          fecha_entrega_prometida: pedido.fecha_entrega_prometida,
          estado: pedido.estado,
          id_cliente: pedido.id_cliente,
          observaciones: pedido.observaciones
        });
        this.cargando = false;
      },
      error: (error) => {
        console.error('Error al cargar pedido:', error);
        this.toastr.error('Error al cargar el pedido.', 'Error');
        this.cargando = false;
        this.volver();
      }
    });
  }

  guardar(): void {
    if (this.pedidoForm.invalid) {
      this.toastr.warning('Por favor complete todos los campos requeridos.', 'Formulario incompleto');
      return;
    }

    if (!this.modoEdicion && this.productosAgregados.length === 0) {
      this.toastr.warning('Debe agregar al menos un producto al pedido.', 'Sin productos');
      return;
    }

    this.guardando = true;
    const formValue = this.pedidoForm.value;

    if (this.modoEdicion && this.idPedido) {
      // Actualizar pedido existente
      const { cod_pedido, ...rest } = formValue; // Eliminar cod_pedido si existe
      const pedidoUpdate: PedidoUpdate = { ...rest, total: this.totalPedido };
      this.pedidosService.actualizarPedido(this.idPedido, pedidoUpdate).subscribe({
        next: () => {
          this.toastr.success('Pedido actualizado correctamente.', 'Éxito');
          this.guardando = false;
          this.volver();
        },
        error: (error) => {
          console.error('Error al actualizar pedido:', error);
          this.toastr.error('Error al actualizar el pedido.', 'Error');
          this.guardando = false;
        }
      });
    } else {
      // Crear nuevo pedido con productos
      const fechaCreacion = new Date().toISOString().split('T')[0]; // Formato YYYY-MM-DD
      const { cod_pedido, ...rest } = formValue; // Eliminar cod_pedido si existe
      const pedidoCreate: PedidoCreate = { ...rest, total: this.totalPedido, fecha_creacion: fechaCreacion };
      console.log('Creando pedido con total:', this.totalPedido);
      console.log('Payload completo:', pedidoCreate);
      this.pedidosService.crearPedido(pedidoCreate).subscribe({
        next: (pedido) => {
          // Ahora agregar todos los productos
          this.guardarProductos(pedido.id_pedido);
        },
        error: (error) => {
          console.error('Error al crear pedido:', error);
          this.toastr.error('Error al crear el pedido.', 'Error');
          this.guardando = false;
        }
      });
    }
  }

  guardarProductos(idPedido: number): void {
    let productosGuardados = 0;
    const totalProductos = this.productosAgregados.length;

    this.productosAgregados.forEach((producto, index) => {
      // Enviar todos los campos requeridos por la base de datos
      const detalle: any = {
        id_pedido: idPedido,
        tipo_prenda: producto.tipo_prenda,
        cuello: producto.cuello,
        manga: producto.manga,
        color: producto.color,
        talla: producto.talla,
        material: producto.material,
        cantidad: producto.cantidad,
        precio_unitario: producto.precio_unitario
      };

      this.pedidosService.crearDetallePedido(detalle).subscribe({
        next: () => {
          productosGuardados++;
          if (productosGuardados === totalProductos) {
            this.toastr.success('Pedido y productos guardados correctamente.', 'Éxito');
            this.guardando = false;
            this.volver();
          }
        },
        error: (error) => {
          console.error('Error al guardar producto:', error);
          this.toastr.error(`Error al guardar producto ${index + 1}.`, 'Error');
          this.guardando = false;
        }
      });
    });
  }

  agregarProducto(): void {
    if (this.detalleForm.invalid) {
      this.toastr.warning('Complete todos los campos del producto.', 'Datos incompletos');
      Object.keys(this.detalleForm.controls).forEach(key => {
        this.detalleForm.get(key)?.markAsTouched();
      });
      return;
    }

    const formValue = this.detalleForm.value;
    const cantidad = Number(formValue.cantidad);
    const precioUnitario = Number(formValue.precio_unitario);
    const subtotal = Math.round(cantidad * precioUnitario * 100) / 100;
    
    const producto = {
      id_precio: formValue.id_precio,
      descripcion: formValue.descripcion,
      material: formValue.material,
      talla: formValue.talla,
      tipo_prenda: formValue.tipo_prenda,
      cuello: formValue.cuello,
      manga: formValue.manga,
      color: formValue.color,
      cantidad: cantidad,
      precio_unitario: precioUnitario,
      subtotal: subtotal
    };

    this.productosAgregados.push(producto);
    this.calcularTotal();
    this.toastr.success('Producto agregado al pedido.', 'Éxito');
    
    // Resetear formulario
    this.detalleForm.reset({ 
      id_precio: null,
      cantidad: 1,
      precio_unitario: 0
    });
    this.precioSugerido = null;
  }

  eliminarProducto(index: number): void {
    this.productosAgregados.splice(index, 1);
    this.calcularTotal();
    this.toastr.info('Producto eliminado.', 'Información');
  }

  calcularTotal(): void {
    const total = this.productosAgregados.reduce((sum, prod) => sum + prod.subtotal, 0);
    // Redondear a 2 decimales para evitar problemas de precisión
    this.totalPedido = Math.round(total * 100) / 100;
  }

  volver(): void {
    this.router.navigate(['/menu/pedidos']);
  }
}
