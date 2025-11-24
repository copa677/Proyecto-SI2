import { Component, OnInit } from '@angular/core';
import { FacturasService, Factura } from '../../services_back/facturas.service';
import { ToastrService } from 'ngx-toastr';

type EstadoPago = 'pendiente' | 'completado' | 'fallido' | 'reembolsado';
type MetodoPago = 'efectivo' | 'transferencia' | 'tarjeta';

interface FacturaRow {
  id_factura: number;
  id_pedido: number;
  numero_factura: string;
  cod_factura: string;
  fecha_emision: string;
  fecha_creacion: string;
  fecha_vencimiento: string;
  monto_total: number;
  stripe_payment_intent_id?: string;
  stripe_checkout_session_id?: string;
  estado_pago: EstadoPago;
  metodo_pago?: MetodoPago;
  fecha_pago?: string;
  codigo_autorizacion?: string;
  ultimos_digitos_tarjeta?: string;
  tipo_tarjeta?: string;
  observaciones?: string;
  pedido?: any;
}
@Component({
  selector: 'app-facturas',
  templateUrl: './facturas.component.html',
  styleUrls: ['./facturas.component.css']
})

export class FacturasComponent implements OnInit {
  facturas: FacturaRow[] = [];

  showForm = false;
  editMode = false;
  filtroEstado: '' | EstadoPago = '';
  filtroMetodo: '' | MetodoPago = '';
  busqueda = '';
  cargando = false;
  errorMsg = '';

  form: FacturaRow = this.vacio();

  constructor(
    private facturasSrv: FacturasService,
    private toastr: ToastrService
  ) { }

  ngOnInit(): void {
    this.cargarFacturas();
  }

  cargarFacturas(): void {
    this.cargando = true;
    this.errorMsg = '';
    this.facturasSrv.obtenerFacturas().subscribe({
      next: (lista) => {
        this.facturas = (lista || []).map((f: any) => ({
          id_factura: f.id_factura ?? f.id ?? 0,
          id_pedido: f.id_pedido ?? 0,
          numero_factura: f.numero_factura ?? f.cod_factura ?? '',
          cod_factura: f.cod_factura ?? '',
          fecha_emision: f.fecha_emision ?? f.fecha_creacion ?? '',
          fecha_creacion: f.fecha_creacion ?? '',
          fecha_vencimiento: f.fecha_vencimiento ?? '',
          monto_total: f.monto_total ?? 0,
          stripe_payment_intent_id: f.stripe_payment_intent_id,
          stripe_checkout_session_id: f.stripe_checkout_session_id,
          estado_pago: (f.estado_pago as EstadoPago) ?? 'pendiente',
          metodo_pago: f.metodo_pago as MetodoPago,
          fecha_pago: f.fecha_pago,
          codigo_autorizacion: f.codigo_autorizacion,
          ultimos_digitos_tarjeta: f.ultimos_digitos_tarjeta,
          tipo_tarjeta: f.tipo_tarjeta,
          observaciones: f.observaciones,
          pedido: f.pedido
        }));
        this.cargando = false;
      },
      error: (err) => {
        this.errorMsg = 'No se pudo cargar las facturas.';
        console.error('Error obtenerFacturas:', err);
        this.cargando = false;
      },
    });
  }

  vacio(): FacturaRow {
    return {
      id_factura: 0,
      id_pedido: 0,
      numero_factura: '',
      cod_factura: '',
      fecha_emision: '',
      fecha_creacion: '',
      fecha_vencimiento: '',
      monto_total: 0,
      estado_pago: 'pendiente',
      metodo_pago: 'efectivo',
      observaciones: ''
    };
  }

  abrirCrear(): void {
    this.form = this.vacio();
    this.editMode = false;
    this.showForm = true;
  }

  abrirEditar(f: FacturaRow): void {
    this.form = { ...f };
    this.editMode = true;
    this.showForm = true;
  }

  cancelar(): void { 
    this.showForm = false; 
    this.editMode = false;
  }

  guardar(): void {
    const f = this.form;
    
    // Validaciones básicas
    if (!f.id_pedido || f.id_pedido <= 0) {
      this.toastr.warning('El ID del pedido es requerido', 'Validación');
      return;
    }
    
    if (!f.monto_total || f.monto_total <= 0) {
      this.toastr.warning('El monto total debe ser mayor a 0', 'Validación');
      return;
    }

    if (!this.editMode) {
      // Crear factura manual
      const payload = {
        id_pedido: f.id_pedido,
        metodo_pago: f.metodo_pago || 'efectivo',
        monto_total: f.monto_total,
        observaciones: f.observaciones
      };

      this.cargando = true;
      this.facturasSrv.crearFacturaManual(payload).subscribe({
        next: (facturaCreada) => {
          this.toastr.success('Factura creada correctamente', 'Éxito');
          this.showForm = false;
          this.cargarFacturas();
        },
        error: (err) => {
          this.toastr.error('No se pudo crear la factura', 'Error');
          this.errorMsg = 'No se pudo crear la factura.';
          this.cargando = false;
        },
      });
    } else {
      // En modo edición, podrías implementar actualización si tu backend lo permite
      this.toastr.warning('La edición de facturas no está implementada', 'Información');
    }
  }

  eliminar(f: FacturaRow): void {
    if (!confirm(`¿Está seguro de eliminar la factura ${f.numero_factura}?`)) return;

    // Nota: Tu backend actual no tiene endpoint para eliminar facturas
    // Esto es un ejemplo de cómo se implementaría si existiera
    this.toastr.warning('La eliminación de facturas no está disponible', 'Información');
  }

  descargarPDF(idFactura: number): void {
    this.facturasSrv.descargarPDF(idFactura).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `factura-${idFactura}.pdf`;
        a.click();
        window.URL.revokeObjectURL(url);
        this.toastr.success('PDF descargado correctamente', 'Éxito');
      },
      error: (err) => {
        this.toastr.error('No se pudo descargar el PDF', 'Error');
        console.error('Error descargarPDF:', err);
      },
    });
  }

  procesarPagoStripe(f: FacturaRow): void {
    if (f.estado_pago === 'completado') {
      this.toastr.info('Esta factura ya está pagada', 'Información');
      return;
    }

    this.facturasSrv.crearSesionPago(f.id_pedido).subscribe({
      next: (response) => {
        window.location.href = response.checkout_url;
      },
      error: (err) => {
        this.toastr.error('No se pudo procesar el pago', 'Error');
        console.error('Error crearSesionPago:', err);
      },
    });
  }

  get filtrados(): FacturaRow[] {
    const q = this.busqueda.trim().toLowerCase();
    return this.facturas.filter((f) => {
      const estadoOk = this.filtroEstado ? f.estado_pago === this.filtroEstado : true;
      const metodoOk = this.filtroMetodo ? f.metodo_pago === this.filtroMetodo : true;
      const text = `${f.numero_factura} ${f.cod_factura} ${f.id_pedido} ${f.monto_total}`.toLowerCase();
      const buscaOk = q ? text.includes(q) : true;
      return estadoOk && metodoOk && buscaOk;
    });
  }
}
