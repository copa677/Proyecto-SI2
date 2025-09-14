import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { finalize } from 'rxjs/operators';
import { LoginService } from 'src/app/services_back/login.service'; // ajusta la ruta
import { Usuario } from 'src/interface/user';              // ajusta la ruta

@Component({
  selector: 'app-notes',
  templateUrl: './notes.component.html',
  styleUrls: ['./notes.component.css'],
})
export class NotesComponent {
  username = '';
  password = '';
  loading = false;

  constructor(
    private loginService: LoginService,
    private router: Router
  ) {}

  login() {
    if (this.loading) return;
    if (!this.username || !this.password) return;

    this.loading = true;

    const user: Usuario = {
      username: this.username,
      password: this.password
    };

    this.loginService.login(user)
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        // Si tu backend devuelve string (token plano):
        next: (res: any) => {
          const token = typeof res === 'string' ? res : res?.token; // tolerante a { token }
          if (!token) {
            alert('No se recibió el token del servidor');
            return;
          }
          localStorage.setItem('token', token);
          this.router.navigate(['/menu/dashboard']);
        },
        error: (e) => {
          const msg = e?.error?.detail || e?.error?.message || 'Usuario o contraseña incorrectos';
          alert(msg);
        },
      });
  }
}
