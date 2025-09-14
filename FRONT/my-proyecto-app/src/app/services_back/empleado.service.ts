import { Injectable } from '@angular/core';
import { Usuario } from '../../interface/user';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment.development';
import { Empleado } from '../../interface/empleado';
@Injectable({
  providedIn: 'root'
})
export class EmpleadoService {
  private myAppUrl: String;
  private myApiUrl: String;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/empleado';
  }

  getEmpleados():Observable<Empleado[]> {
    return this.http.get<Empleado[]>(`${this.myAppUrl}${this.myApiUrl}/getEmpleados`);
  }

  registrarEmpleados(newEmpleado: Empleado):Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/registrar`,newEmpleado);
  }

  actualizar_Empleados(newEmpleado: Empleado):Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/actualizar`,newEmpleado);
  }

  get_Empleado(nombre: string):Observable<Empleado> {
    return this.http.get<Empleado>(`${this.myAppUrl}${this.myApiUrl}/getEmpleado/${nombre}`);
  }

  get_Empleado_ID_User(id_usuario: number):Observable<Empleado> {
    return this.http.get<Empleado>(`${this.myAppUrl}${this.myApiUrl}/getEmpleadoID/${id_usuario}`);
  }

  eliminar_Empleado(empleado: Empleado):Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/eliminar`,empleado);
  }

}
