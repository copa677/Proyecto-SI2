// src/app/services_back/cliente.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';

// Esta interfaz define el payload para CREAR un cliente (según tu API)
export interface ClienteCreatePayload {
  nombre_completo: string;
  direccion: string;
  telefono: string;
  fecha_nacimiento: string; // 'YYYY-MM-DD'
  email: string;
  password?: string; // Opcional al crear si se genera auto, pero tu API lo pide
  tipo_usuario: string; // 'Cliente'
  name_user: string; // El nombre de usuario
}

// Esta interfaz define el payload para ACTUALIZAR (según tu API)
export interface ClienteUpdatePayload {
  id?: number; // El ID del cliente
  nombre_completo: string;
  direccion: string;
  telefono: string;
  fecha_nacimiento: string; // 'YYYY-MM-DD'
  estado: 'activo' | 'inactivo';
  email?: string; // Opcional para actualizar
  password?: string; // Opcional para actualizar
  tipo_usuario?: string; // Opcional para actualizar
}

// Esta es la data que esperamos RECIBIR de la API (según tu Serializer)
export interface ClienteApiResponse {
  id: number;
  id_usuario: number;
  estado: 'activo' | 'inactivo';
  nombre_completo: string;
  direccion: string;
  telefono: string;
  fecha_nacimiento: string; // 'YYYY-MM-DD'
}


@Injectable({
  providedIn: 'root'
})
export class ClienteService {

  // Asumiendo que la URL base está en environments
  private baseUrl = `${environment.endpoint}/clientes`;

  constructor(private http: HttpClient) { }

  /**
   * GET: /api/clientes/listar/
   * Obtiene la lista de todos los clientes.
   */
  getClientes(): Observable<ClienteApiResponse[]> {
    return this.http.get<ClienteApiResponse[]>(`${this.baseUrl}/listar/`);
  }

  /**
   * POST: /api/clientes/crear/
   * Registra un nuevo cliente Y su usuario asociado.
   */
  registrarCliente(payload: ClienteCreatePayload): Observable<any> {
    return this.http.post(`${this.baseUrl}/crear/`, payload);
  }

  /**
   * PUT: /api/clientes/actualizar/<id_cliente>/
   * Actualiza un cliente Y su usuario asociado.
   */
  actualizarCliente(idCliente: number, payload: ClienteUpdatePayload): Observable<any> {
    return this.http.put(`${this.baseUrl}/actualizar/${idCliente}/`, payload);
  }

  /**
   * DELETE: /api/clientes/eliminar/<id_cliente>/
   * Elimina un cliente Y su usuario asociado.
   */
  eliminarCliente(idCliente: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/eliminar/${idCliente}/`);
  }
}