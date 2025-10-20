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
  isMobileMenuOpen = false;

  mobileSubmenus: { [key: string]: boolean } = {
    personal: false,
    usuarios: false,
    produccion: false,
    reportes: false
  };

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

  toggleMobileMenu() { this.isMobileMenuOpen = !this.isMobileMenuOpen; }

  toggleMobileSubmenu(submenu: string) {
    // Optional: close other submenus when one is opened
    // for (const key in this.mobileSubmenus) {
    //   if (key !== submenu) {
    //     this.mobileSubmenus[key] = false;
    //   }
    // }
    this.mobileSubmenus[submenu] = !this.mobileSubmenus[submenu];
  }
  
  logout() {
    this.login.logout().subscribe({
      next: () => {
        console.log('Cierre de sesión exitoso en el backend');
        this.ejecutarLogout();
      },
      error: (err) => {
        console.error('Error en el cierre de sesión del backend:', err);
        this.ejecutarLogout(); // Aún así, desloguear al usuario en el frontend
      }
    });
  }

  private ejecutarLogout() {
    localStorage.removeItem('token'); 
    localStorage.removeItem('username'); 
    window.location.href = '/notes';
  }
}
