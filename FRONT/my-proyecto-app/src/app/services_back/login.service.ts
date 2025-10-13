import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment.development';
import { Usuario } from '../../interface/user';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { ToastrService } from 'ngx-toastr';
import { Permisos } from '../../interface/permisos';
import { Empleado } from '../../interface/empleado';

@Injectable({
  providedIn: 'root'
})
export class LoginService {
  private myAppUrl: String;
  private myApiUrl: String;


  constructor(private http: HttpClient, private toastr: ToastrService) {
    this.myAppUrl = environment.endpoint;
    this.myApiUrl = 'api/usuario';
  }

  login(user: Usuario): Observable<string> {
    return this.http.post<string>(`${this.myAppUrl}${this.myApiUrl}/login`, user);
  }
  register(user: Usuario): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/register`, user);
  }
  getUser(id: number): Observable<Usuario> {
    return this.http.get<Usuario>(`${this.myAppUrl}${this.myApiUrl}/getUser/${id}`, {});
  }
  getuser(): Observable<Usuario[]> {
    return this.http.get<Usuario[]>(`${this.myAppUrl}${this.myApiUrl}/getuser`);
  }

  public getUserIdFromToken(): number | null {
    const token = localStorage.getItem('token');
    if (token) {
      const tokenParts = token.split('.');
      if (tokenParts.length === 3) {
        try {
          const payload = JSON.parse(atob(tokenParts[1]));
          return payload.id;
        } catch (error) {
          this.toastr.error('No se pudo decodificar el token.', 'Error');
          return null;
        }
      } else {
        this.toastr.error('El token no tiene el formato esperado.', 'Error');
        return null;
      }
    } else {
      this.toastr.error('No se encontró un token en el localStorage.', 'Error');
      return null;
    }
  }

  // Decodifica Base64URL (JWT) de forma segura
  private b64urlDecode(input: string): string {
    input = input.replace(/-/g, '+').replace(/_/g, '/');
    const pad = input.length % 4;
    if (pad) input += '='.repeat(4 - pad);
    return atob(input);
  }

  public getUsernameFromToken(): string | null {
    const token = localStorage.getItem('token');
    if (!token) return null;

    const parts = token.split('.');
    if (parts.length !== 3) return null;

    try {
      const payload = JSON.parse(this.b64urlDecode(parts[1]));
      return payload.name_user || null;   // ← en tu token viene como name_user
    } catch {
      return null;
    }
  }



  recover_password(email: string): Observable<string> {
    return this.http.post<string>(`${this.myAppUrl}api/recuperar_password/enviarEMAIL`, { email });
  }

  verif_cod(codigo: string): Observable<string> {
    return this.http.post<string>(`${this.myAppUrl}api/recuperar_password/verificarCOD`, { codigo });
  }

  username_email(email: string): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/username_email/${email}`, {});
  }

  new_password(username: String, password: String): Observable<string> {
    return this.http.post<string>(`${this.myAppUrl}${this.myApiUrl}/newPassword/${username}`, { password });
  }

  insert_permisos(permisos: Permisos): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/permisos`, permisos);
  }

  get_permisos_user(username: string): Observable<Permisos[]> {
    return this.http.get<Permisos[]>(`${this.myAppUrl}${this.myApiUrl}/getpermisosUser/${username}`, {});
  }
  get_permisos_user_ventana(username: string, ventana: string): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/getpermisosUser_Ventana/${username}/${ventana}`, {});
  }
  actualizarEmpleadoUsuario(emepleado: Empleado): Observable<any> {
    return this.http.post<any>(`${this.myAppUrl}${this.myApiUrl}/actualizarEmpleadoUsuario`, emepleado);
  }

  insertarURL(id_usuario: number, url: string): Observable<any> {
    return this.http.post<any>(`${this.myAppUrl}${this.myApiUrl}/insertarURL`, { id_usuario, url });
  }
  getURL(id_usuario: number): Observable<any> {
    return this.http.get<any>(`${this.myAppUrl}${this.myApiUrl}/getURL/${id_usuario}`);
  }

  subirImagen(file: File): Observable<string> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', 'Examen1_S12');
    formData.append('cloud_name', 'dmfl4ahiy');

    return new Observable<string>((observer) => {
      this.http.post<any>('https://api.cloudinary.com/v1_1/dmfl4ahiy/image/upload', formData)
        .subscribe({
          next: (res) => {
            observer.next(res.secure_url);  // devolvemos la URL segura
            observer.complete();
          },
          error: (err) => {
            observer.error(err);
          }
        });
    });
  }

  // Actualizar usuario
  actualizarUsuario(id: number, datos: Partial<Usuario>): Observable<any> {
    return this.http.patch<any>(`${this.myAppUrl}${this.myApiUrl}/actualizar/${id}`, datos);
  }

  // Eliminar usuario
  eliminarUsuario(id: number): Observable<any> {
    return this.http.delete<any>(`${this.myAppUrl}${this.myApiUrl}/eliminar/${id}`);
  }
}
