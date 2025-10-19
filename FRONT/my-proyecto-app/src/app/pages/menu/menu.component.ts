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
  ) { }

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
  this.bitacoraService.registrarAccion(
    'Cierre de sesión',
    `El usuario ${this.userName} ha cerrado sesión`
  );

  // Espera un poquito antes del redirect para que el registro se complete
  setTimeout(() => this.ejecutarLogout(), 2000);
}



  private ejecutarLogout() {
    localStorage.removeItem('token');
    localStorage.removeItem('username');
    window.location.href = '/notes';
  }
}
