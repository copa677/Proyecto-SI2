import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

export interface Factura {
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
  estado_pago: 'pendiente' | 'pagada' | 'vencida' | 'cancelada' | 'completado' | 'fallido' | 'reembolsado';
  metodo_pago?: string;
  fecha_pago?: string;
  codigo_autorizacion?: string;
  ultimos_digitos_tarjeta?: string;
  tipo_tarjeta?: string;
  observaciones?: string;
  pedido?: any;
}

export interface SesionPagoResponse {
  checkout_url: string;
  session_id: string;
  factura_id: number;
  cod_factura: string;
  monto_total: number;
}

@Injectable({
  providedIn: 'root'
})
export class FacturasService {
  private apiUrl = `${environment.endpoint}api/facturas`;

  constructor(private http: HttpClient) { }

  // Crear sesión de pago con Stripe
  crearSesionPago(idPedido: number): Observable<SesionPagoResponse> {
    return this.http.post<SesionPagoResponse>(`${this.apiUrl}/pago/crear-sesion/${idPedido}/`, {});
  }

  // Verificar estado de pago
  verificarEstadoPago(idFactura: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/pago/verificar/${idFactura}/`);
  }

  // Obtener todas las facturas (para admin o cliente según permisos)
  obtenerFacturas(): Observable<Factura[]> {
    return this.http.get<Factura[]>(`${this.apiUrl}/`);
  }

  // Obtener facturas de un cliente específico
  obtenerFacturasCliente(): Observable<Factura[]> {
    const idCliente = localStorage.getItem('id_cliente');
    if (!idCliente) {
      throw new Error('No se encontró el ID del cliente');
    }
    return this.http.get<Factura[]>(`${this.apiUrl}/mis-facturas/?id_cliente=${idCliente}`);
  }

  // Obtener una factura por ID
  obtenerFacturaPorId(idFactura: number): Observable<Factura> {
    return this.http.get<Factura>(`${this.apiUrl}/${idFactura}/`);
  }

  // Descargar PDF de factura
  descargarPDF(idFactura: number): Observable<Blob> {
    return this.http.get(`${this.apiUrl}/${idFactura}/pdf/`, { responseType: 'blob' });
  }

  // Crear factura manual (para empleados) sin Stripe
  crearFacturaManual(facturaData: { id_pedido: number; metodo_pago: string; monto_total: number }): Observable<Factura> {
    return this.http.post<Factura>(`${this.apiUrl}/crear-manual/`, facturaData);
  }
}
