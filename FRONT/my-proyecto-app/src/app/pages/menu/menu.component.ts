import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services_back/login.service';
import { BitacoraService } from '../../services_back/bitacora.service';

@Component({
  selector: 'app-menu',
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.css']
})
export class MenuComponent implements OnInit {
  userInitial = '?';
  userName = '';

  showMenu = false;

  constructor(
    private login: LoginService,
    private bitacoraService: BitacoraService
  ) {}

  ngOnInit(): void {
    const username = this.login.getUsernameFromToken();
    if (username && username.trim().length > 0) {
      this.userName = username.trim();
      this.userInitial = this.userName.charAt(0).toUpperCase();
      // si prefieres dos iniciales:
      // this.userInitial = this.userName.split(/\s+/).slice(0,2).map(s => s[0]).join('').toUpperCase();
    }
  }

  toggleMenu() { this.showMenu = !this.showMenu; }
  
  logout() {
    // Registrar en bitácora antes de cerrar sesión
    this.bitacoraService.registrarAccion(
      'Cierre de sesión',
      `El usuario ${this.userName} ha cerrado sesión en el sistema`
    ).subscribe({
      next: () => {
        console.log('Cierre de sesión registrado en bitácora');
        this.ejecutarLogout();
      },
      error: (err) => {
        console.error('Error al registrar en bitácora:', err);
        this.ejecutarLogout(); // Continuar con logout aunque falle el registro
      }
    });
  }

  private ejecutarLogout() {
    localStorage.removeItem('token'); 
    localStorage.removeItem('username'); 
    window.location.href = '/notes';
  }
}
