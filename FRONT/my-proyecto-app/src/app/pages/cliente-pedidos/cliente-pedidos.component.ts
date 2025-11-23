import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PedidosService } from '../../services_back/pedidos.service';
import { PrecioService, PrecioProducto } from '../../services_back/precio.service';
import { FacturasService } from '../../services_back/facturas.service';
import { Pedido, DetallePedido } from '../../../interface/pedidos';
import { ToastrService } from 'ngx-toastr';

interface ProductoAgregado {
  id_precio: number;
  descripcion: string;
  material: string;
  talla: string;
  tipo_prenda: string;
  cuello: string;
  manga: string;
  color: string;
  cantidad: number;
  precio_unitario: number;
  subtotal: number;
}

@Component({
  selector: 'app-cliente-pedidos',
  templateUrl: './cliente-pedidos.component.html',
  styleUrls: ['./cliente-pedidos.component.css']
})
export class ClientePedidosComponent implements OnInit {
  pedidos: Pedido[] = [];
  mostrarFormularioNuevoPedido = false;
  cargando = false;
  idCliente: number = 0;

  // Datos del catálogo (desde la BD)
  productos: PrecioProducto[] = [];
  productosFiltrados: PrecioProducto[] = [];
  productoSeleccionado: PrecioProducto | null = null;
  
  // Búsqueda y filtros
  busquedaProducto: string = '';
  mostrarCatalogo = false;
  
  // Datos para el formulario
  coloresComunes: string[] = [
    'Blanco', 'Negro', 'Azul', 'Rojo', 'Verde', 'Amarillo', 'Gris', 
    'Celeste', 'Naranja', 'Marrón', 'Beige', 'Violeta', 'Rosado', 
    'Turquesa', 'Bordó', 'Fucsia', 'Lila'
  ];
  
  tiposPrenda = ['polera', 'camisa', 'pantalón', 'chaqueta'];
  tiposCuello = ['cuello redondo', 'cuello V', 'cuello polo', 'cuello clásico', 'cuello mao'];
  tiposManga = ['manga corta', 'manga larga', 'sin mangas', 'manga 3/4'];

  // Producto en construcción
  cantidad: number = 1;
  colorSeleccionado: string = '';
  tipoPrendaSeleccionado: string = '';
  cuelloSeleccionado: string = '';
  mangaSeleccionada: string = '';

  productosAgregados: ProductoAgregado[] = [];
  totalPedido: number = 0;

  constructor(
    private pedidosService: PedidosService,
    private precioService: PrecioService,
    private facturasService: FacturasService,
    private toastr: ToastrService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Obtener ID del cliente desde localStorage (se guardó al hacer login)
    const idClienteStr = localStorage.getItem('id_cliente');
    if (idClienteStr) {
      this.idCliente = parseInt(idClienteStr);
      this.cargarPedidos();
      this.cargarProductos();
    } else {
      this.toastr.error('No se encontró información del cliente', 'Error');
      this.router.navigate(['/notes']);
    }
  }

  cargarProductos(): void {
    this.cargando = true;
    this.precioService.listarPrecios().subscribe({
      next: (productos) => {
        // Filtrar solo productos activos
        this.productos = productos.filter(p => p.activo);
        console.log('Productos cargados:', this.productos); // Debug
        this.productosFiltrados = this.productos;
        this.cargando = false;
      },
      error: (error) => {
        console.error('Error al cargar productos:', error);
        this.toastr.error('Error al cargar el catálogo de productos', 'Error');
        this.cargando = false;
      }
    });
  }

  cargarPedidos(): void {
    this.cargando = true;
    this.pedidosService.listarTodosPedidos().subscribe({
      next: (pedidos) => {
        // Filtrar solo pedidos del cliente actual
        this.pedidos = pedidos.filter(p => p.id_cliente === this.idCliente);
        this.cargando = false;
      },
      error: (error) => {
        console.error('Error al cargar pedidos:', error);
        this.toastr.error('Error al cargar los pedidos', 'Error');
        this.cargando = false;
      }
    });
  }

  toggleFormularioNuevoPedido(): void {
    this.mostrarFormularioNuevoPedido = !this.mostrarFormularioNuevoPedido;
    console.log('Carrito abierto. Productos:', this.productosAgregados.length); // Debug
    // NO resetear el formulario aquí, solo cuando se crea un nuevo pedido o se cancela
  }

  resetearFormulario(): void {
    this.productoSeleccionado = null;
    this.cantidad = 1;
    this.colorSeleccionado = '';
    this.tipoPrendaSeleccionado = '';
    this.cuelloSeleccionado = '';
    this.mangaSeleccionada = '';
    this.busquedaProducto = '';
    // NO resetear productosAgregados aquí, solo en crearPedido cuando sea exitoso
  }

  filtrarProductos(): void {
    const busqueda = this.busquedaProducto.toLowerCase();
    if (busqueda) {
      this.productosFiltrados = this.productos.filter(p =>
        p.decripcion.toLowerCase().includes(busqueda) ||
        p.material.toLowerCase().includes(busqueda) ||
        p.talla.toLowerCase().includes(busqueda)
      );
    } else {
      this.productosFiltrados = this.productos;
    }
  }

  seleccionarProducto(producto: PrecioProducto): void {
    this.productoSeleccionado = producto;
    this.mostrarCatalogo = false;
    this.busquedaProducto = `${producto.decripcion} - ${producto.material} - ${producto.talla}`;
    
    // Resetear selecciones
    this.colorSeleccionado = '';
    this.tipoPrendaSeleccionado = '';
    this.cuelloSeleccionado = '';
    this.mangaSeleccionada = '';
    this.cantidad = 1;
  }

  agregarProducto(): void {
    if (!this.productoSeleccionado) {
      this.toastr.warning('Por favor selecciona un producto del catálogo', 'Advertencia');
      return;
    }

    if (!this.colorSeleccionado || !this.tipoPrendaSeleccionado || 
        !this.cuelloSeleccionado || !this.mangaSeleccionada || this.cantidad <= 0) {
      this.toastr.warning('Por favor completa todos los campos del producto', 'Advertencia');
      return;
    }

    const productoAgregar: ProductoAgregado = {
      id_precio: this.productoSeleccionado.id_precio,
      descripcion: this.productoSeleccionado.decripcion, // decripcion del backend -> descripcion en frontend
      material: this.productoSeleccionado.material,
      talla: this.productoSeleccionado.talla,
      tipo_prenda: this.tipoPrendaSeleccionado,
      cuello: this.cuelloSeleccionado,
      manga: this.mangaSeleccionada,
      color: this.colorSeleccionado,
      cantidad: this.cantidad,
      precio_unitario: this.productoSeleccionado.precio_base,
      subtotal: this.cantidad * this.productoSeleccionado.precio_base
    };
    
    console.log('Producto agregado:', productoAgregar); // Debug
    this.productosAgregados.push(productoAgregar);
    this.calcularTotal();
    
    // Cerrar el modal de selección
    this.productoSeleccionado = null;
    
    // Resetear campos
    this.colorSeleccionado = '';
    this.tipoPrendaSeleccionado = '';
    this.cuelloSeleccionado = '';
    this.mangaSeleccionada = '';
    this.cantidad = 1;
    
    this.toastr.success('Producto agregado al carrito', 'Éxito');
  }  eliminarProducto(index: number): void {
    this.productosAgregados.splice(index, 1);
    this.calcularTotal();
    this.toastr.info('Producto eliminado', 'Info');
  }

  calcularTotal(): void {
    this.totalPedido = this.productosAgregados.reduce((sum, prod) => sum + prod.subtotal, 0);
    console.log('Total calculado:', this.totalPedido, 'Productos:', this.productosAgregados.length); // Debug
  }

  crearPedido(): void {
    if (this.productosAgregados.length === 0) {
      this.toastr.warning('Debes agregar al menos un producto al pedido', 'Advertencia');
      return;
    }

    this.cargando = true;

    // Crear pedido
    const nuevoPedido = {
      fecha_entrega_prometida: this.obtenerFechaEntregaPromedio(),
      estado: 'cotizacion',
      id_cliente: this.idCliente,
      total: this.totalPedido,
      fecha_creacion: new Date().toISOString().split('T')[0],
      observaciones: 'Pedido creado desde portal del cliente'
    };

    this.pedidosService.crearPedido(nuevoPedido).subscribe({
      next: (pedido) => {
        // Agregar detalles del pedido
        this.guardarProductos(pedido.id_pedido);
      },
      error: (error) => {
        console.error('Error al crear pedido:', error);
        this.toastr.error('Error al crear el pedido', 'Error');
        this.cargando = false;
      }
    });
  }

  guardarProductos(idPedido: number): void {
    let productosGuardados = 0;
    const totalProductos = this.productosAgregados.length;

    this.productosAgregados.forEach((producto) => {
      const detalle: any = {
        id_pedido: idPedido,
        id_precio: producto.id_precio,
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
            this.toastr.success('Pedido creado exitosamente', 'Éxito');
            this.cargando = false;
            this.mostrarFormularioNuevoPedido = false;
            
            // Limpiar el carrito después de crear el pedido exitosamente
            this.productosAgregados = [];
            this.totalPedido = 0;
            this.resetearFormulario();
            
            this.cargarPedidos();
          }
        },
        error: (error) => {
          console.error('Error al guardar producto:', error);
          this.toastr.error('Error al guardar un producto', 'Error');
          this.cargando = false;
        }
      });
    });
  }

  obtenerFechaEntregaPromedio(): string {
    const fecha = new Date();
    fecha.setDate(fecha.getDate() + 15); // 15 días de plazo promedio
    return fecha.toISOString().split('T')[0];
  }

  pagarPedido(pedido: Pedido): void {
    if (pedido.estado === 'cancelado') {
      this.toastr.error('No se puede pagar un pedido cancelado', 'Error');
      return;
    }

    this.cargando = true;
    this.facturasService.crearSesionPago(pedido.id_pedido).subscribe({
      next: (response) => {
        this.toastr.success('Redirigiendo a la pasarela de pago...', 'Éxito');
        // Redirigir a Stripe Checkout
        window.location.href = response.checkout_url;
      },
      error: (error) => {
        console.error('Error al crear sesión de pago:', error);
        this.toastr.error(error.error?.error || 'Error al procesar el pago', 'Error');
        this.cargando = false;
      }
    });
  }

  verDetallePedido(pedido: Pedido): void {
    this.router.navigate(['/cliente/pedidos', pedido.id_pedido]);
  }

  irADashboard(): void {
    this.router.navigate(['/cliente/dashboard']);
  }

  irAFacturas(): void {
    this.router.navigate(['/cliente/facturas']);
  }

  volverDashboard(): void {
    this.router.navigate(['/cliente/dashboard']);
  }

  getEstadoClase(estado: string): string {
    const clases: any = {
      'cotizacion': 'bg-yellow-100 text-yellow-800',
      'confirmado': 'bg-blue-100 text-blue-800',
      'en_produccion': 'bg-purple-100 text-purple-800',
      'completado': 'bg-green-100 text-green-800',
      'entregado': 'bg-gray-100 text-gray-800',
      'cancelado': 'bg-red-100 text-red-800'
    };
    return clases[estado] || 'bg-gray-100 text-gray-800';
  }

  getEstadoTexto(estado: string): string {
    const textos: any = {
      'cotizacion': 'Cotización',
      'confirmado': 'Confirmado',
      'en_produccion': 'En Producción',
      'completado': 'Completado',
      'entregado': 'Entregado',
      'cancelado': 'Cancelado'
    };
    return textos[estado] || estado;
  }
}
