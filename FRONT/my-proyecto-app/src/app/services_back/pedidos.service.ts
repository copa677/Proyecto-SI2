import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';
import { 
  Pedido, 
  PedidoCreate, 
  PedidoUpdate, 
  DetallePedido, 
  DetallePedidoCreate, 
  DetallePedidoUpdate, 
  PrecioSugerido 
} from '../../interface/pedidos';

@Injectable({
  providedIn: 'root'
})
export class PedidosService {
  private apiUrl = `${environment.endpoint}api/pedidos`;

  constructor(private http: HttpClient) { }

  // ==================== PEDIDOS ====================
  
  crearPedido(pedido: PedidoCreate): Observable<Pedido> {
    return this.http.post<Pedido>(`${this.apiUrl}/crear/`, pedido);
  }

  listarPedidosActivos(): Observable<Pedido[]> {
    return this.http.get<Pedido[]>(`${this.apiUrl}/listar-todos/`);
  }

  listarTodosPedidos(): Observable<Pedido[]> {
    return this.http.get<Pedido[]>(`${this.apiUrl}/listar-todos/`);
  }

  obtenerPedido(idPedido: number): Observable<Pedido> {
    return this.http.get<Pedido>(`${this.apiUrl}/obtener/${idPedido}/`);
  }

  actualizarPedido(idPedido: number, pedido: PedidoUpdate): Observable<Pedido> {
    return this.http.put<Pedido>(`${this.apiUrl}/actualizar/${idPedido}/`, pedido);
  }

  eliminarPedido(idPedido: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/eliminar/${idPedido}/`);
  }

  // ==================== DETALLES PEDIDO ====================
  
  crearDetallePedido(detalle: DetallePedidoCreate): Observable<DetallePedido> {
    return this.http.post<DetallePedido>(`${this.apiUrl}/detalles/crear/`, detalle);
  }

  listarDetallesPedido(idPedido: number): Observable<DetallePedido[]> {
    return this.http.get<DetallePedido[]>(`${this.apiUrl}/detalles/listar/${idPedido}/`);
  }

  obtenerDetallePedido(idDetalle: number): Observable<DetallePedido> {
    return this.http.get<DetallePedido>(`${this.apiUrl}/detalles/obtener/${idDetalle}/`);
  }

  actualizarDetallePedido(idDetalle: number, detalle: DetallePedidoUpdate): Observable<DetallePedido> {
    return this.http.put<DetallePedido>(`${this.apiUrl}/detalles/actualizar/${idDetalle}/`, detalle);
  }

  eliminarDetallePedido(idDetalle: number): Observable<{ message: string }> {
    return this.http.delete<{ message: string }>(`${this.apiUrl}/detalles/eliminar/${idDetalle}/`);
  }

  // ==================== PRECIOS ====================
  
  buscarPrecioSugerido(tipoPrenda: string, cuello: string, manga: string, material: string): Observable<PrecioSugerido> {
    let params = new HttpParams()
      .set('tipo_prenda', tipoPrenda)
      .set('cuello', cuello)
      .set('manga', manga)
      .set('material', material);
    
    return this.http.get<PrecioSugerido>(`${this.apiUrl}/buscar-precios/`, { params });
  }
}
