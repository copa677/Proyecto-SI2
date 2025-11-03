import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { ToastrService } from 'ngx-toastr';

import { LoginService } from 'src/app/services_back/login.service';
import { BitacoraService } from 'src/app/services_back/bitacora.service';
import { AuthService } from 'src/app/services/auth.service';
import { Usuario } from 'src/interface/user';

@Component({
  selector: 'app-notes',
  templateUrl: './notes.component.html',
  styleUrls: ['./notes.component.css'],
})
export class NotesComponent {
  username = '';
  password = '';

  constructor(
    private loginService: LoginService,
    private bitacoraService: BitacoraService,
    private authService: AuthService,
    private toastr: ToastrService,
    private router: Router
  ) {}

  login() {
    // Validaciones rápidas
    if (!this.username.trim() || !this.password.trim()) {
      this.toastr.warning('Completa usuario y contraseña.', 'Campos requeridos', {
        positionClass: 'toast-bottom-right',
        timeOut: 2500,
      });
      return;
    }

    // OJO: si tu backend espera `username`, manda `username`.
    // Si espera `name_user`, cambia la línea siguiente acorde.
    const user: Usuario = {
      // Si tu interfaz tiene `name_user`, puedes usar:
      // name_user: this.username as any,
      // password: this.password

      // Por defecto, envío `username` y `password` (lo más común en DRF/JWT)
      name_user: this.username as any,
      password: this.password
    };
    this.loginService.login(user).subscribe({
      next: (response: any) => {
        // Soporta varios formatos de respuesta: {token}, {access}, "token"
        const token =
          typeof response === 'string'
            ? response
            : response?.token || response?.access || response?.data?.token;

        if (!token) {
          this.toastr.error('No se recibió el token del servidor.', 'Error', {
            positionClass: 'toast-bottom-right',
          });
          return;
        }

        // Guardar datos del usuario usando AuthService
        const tipo_usuario = response?.tipo_usuario || 'Usuario';
        const name_user = response?.name_user || this.username.trim();
        const email = response?.email || '';
        
        this.authService.setUserData(token, tipo_usuario, name_user, email);
        
        // También mantener compatibilidad con código existente
        localStorage.setItem('username', name_user);
        
        // Registrar en bitácora el inicio de sesión
        this.bitacoraService.registrarAccion(
          'Inicio de sesión',
          `El usuario ${name_user} ha iniciado sesión en el sistema`
        ).subscribe({
          next: () => console.log('Inicio de sesión registrado en bitácora'),
          error: (err) => console.error('Error al registrar en bitácora:', err)
        });
        
        this.toastr.success('¡Bienvenido!', 'Inicio de sesión exitoso', {
          positionClass: 'toast-bottom-right',
          timeOut: 2000,
        });
        this.router.navigate(['/menu/dashboard']);
      },
      error: (e: HttpErrorResponse) => {
        const detail =
          (e?.error && (e.error.detail || e.error.message || e.error.error)) ||
          e?.statusText ||
          'Usuario o contraseña incorrectos';

        this.toastr.error(detail, 'No se pudo iniciar sesión', {
          positionClass: 'toast-bottom-right',
          timeOut: 3000,
        });
        // Opcional: log para depurar
        // console.error('STATUS:', e.status, 'BODY:', e.error);
      },
    });
  }
}
