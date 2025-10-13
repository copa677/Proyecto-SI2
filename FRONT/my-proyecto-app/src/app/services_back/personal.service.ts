import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Empleado {
  nombre_completo: string;
  direccion: string;
  telefono: string;
  rol: string;
  fecha_nacimiento: Date | string;
  estado: string;
  username?: string;
  id_usuario?: number;
}

@Injectable({ providedIn: 'root' })
export class PersonalService {
  private apiUrl = 'http://localhost:8000/api/personal/';

  constructor(private http: HttpClient) {}

  registrarEmpleados(datos: Empleado): Observable<any> {
    return this.http.post(this.apiUrl + 'registrar', datos);
  }

  actualizarEmpleado(datos: Empleado): Observable<any> {
    return this.http.post(this.apiUrl + 'actualizar', datos);
  }

  eliminarEmpleado(id_usuario: number): Observable<any> {
    return this.http.post(this.apiUrl + 'eliminar', { id_usuario });
  }

  getEmpleados(): Observable<any> {
    return this.http.get(this.apiUrl + 'getEmpleados');
  }
}
