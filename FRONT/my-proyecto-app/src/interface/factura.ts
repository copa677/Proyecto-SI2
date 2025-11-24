// interface/factura.ts
export interface Factura {
  id_factura: number;
  id_pedido: number;
  cod_factura: string;
  numero_factura: string;
  fecha_creacion: string;
  fecha_emision: string;
  fecha_vencimiento: string;
  monto_total: number;
  stripe_payment_intent_id?: string;
  stripe_checkout_session_id?: string;
  estado_pago: 'pendiente' | 'completado' | 'fallido' | 'reembolsado';
  metodo_pago?: string;
  fecha_pago?: string;
  codigo_autorizacion?: string;
  ultimos_digitos_tarjeta?: string;
  tipo_tarjeta?: string;
}