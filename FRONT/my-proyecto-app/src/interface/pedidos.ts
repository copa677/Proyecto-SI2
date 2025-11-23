// Interfaces para Pedidos
export interface Pedido {
  id_pedido: number;
  cod_pedido: string;
  fecha_pedido: string;
  fecha_entrega_prometida: string;
  estado: 'cotizacion' | 'confirmado' | 'en_produccion' | 'completado' | 'entregado' | 'cancelado';
  id_cliente: number;
  total: string;
  observaciones: string;
  fecha_creacion: string;
}

export interface PedidoCreate {
  fecha_entrega_prometida: string;
  estado: string;
  id_cliente: number;
  total: number;
  fecha_creacion: string;
  observaciones?: string;
}

export interface PedidoUpdate {
  fecha_entrega_prometida?: string;
  estado?: string;
  id_cliente?: number;
  total?: number;
  observaciones?: string;
}

export interface DetallePedido {
  id_detalle: number;
  id_pedido: number;
  tipo_prenda: 'polera' | 'camisa';
  cuello: string;
  manga: string;
  color: string;
  talla: string;
  material: string;
  cantidad: number;
  precio_unitario: string;
  subtotal: string;
}

export interface DetallePedidoCreate {
  id_pedido: number;
  tipo_prenda: 'polera' | 'camisa';
  cuello: string;
  manga: string;
  color: string;
  talla: string;
  material: string;
  cantidad: number;
  precio_unitario: number;
}

export interface DetallePedidoUpdate {
  tipo_prenda?: 'polera' | 'camisa';
  cuello?: string;
  manga?: string;
  color?: string;
  talla?: string;
  material?: string;
  cantidad?: number;
}

export interface PrecioSugerido {
  tipo_prenda: string;
  cuello: string;
  manga: string;
  material: string;
  precio_sugerido: number;
}
