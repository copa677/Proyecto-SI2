import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services_back/login.service';
import { BitacoraService } from '../../services_back/bitacora.service';
import { PermissionService } from '../../services_back/permission.service';
import { AuthService } from '../../services/auth.service';

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

  // Permisos dinámicos desde la base de datos para todas las ventanas
  pagePermissions: { [key: string]: boolean } = {};

  constructor(
    private login: LoginService,
    private bitacoraService: BitacoraService,
    public permissionService: PermissionService, // Inyectar y hacer público
    public authService: AuthService // Servicio de autenticación
  ) {}

  ngOnInit(): void {
    // Obtener nombre de usuario del AuthService
    const username = this.authService.getUserName() || this.login.getUsernameFromToken();
    if (username && username.trim().length > 0) {
      this.userName = username.trim();
      this.userInitial = this.userName.charAt(0).toUpperCase();
    }

    // Inicializar el rol en el servicio de permisos usando AuthService
    const role = this.authService.getUserRole() || this.login.getRoleFromToken();
    this.permissionService.setUserRole(role ?? '');

    // Cargar permisos dinámicos desde la base de datos
    this.loadPermissions();
  }

  loadPermissions(): void {
    const username = this.userName;

    // Si es admin, tiene todos los permisos
    if (this.authService.isAdmin()) {
      const allPages = [
        'Bitacora', 'Permisos', 'AsignarPermisos', 'Usuarios', 'Clientes',
        'Personal', 'Asistencia', 'Turnos', 'Inventario', 'Lotes',
        'OrdenProduccion', 'Trazabilidad', 'ControlCalidad', 'NotaSalida'
      ];
      allPages.forEach(page => this.pagePermissions[page] = true);
      return;
    }

    // Cargar permisos de todas las ventanas desde la BD
    const ventanas = [
      'Bitacora', 'Permisos', 'AsignarPermisos', 'Usuarios', 'Clientes',
      'Personal', 'Asistencia', 'Turnos', 'Inventario', 'Lotes',
      'OrdenProduccion', 'Trazabilidad', 'ControlCalidad', 'NotaSalida'
    ];

    ventanas.forEach(ventana => {
      this.permissionService.puedeRealizarAccion(username, ventana, 'ver').subscribe(
        canAccess => this.pagePermissions[ventana] = canAccess
      );
    });
  }

  // Método helper para verificar permisos en el template
  canAccess(ventana: string): boolean {
    return this.pagePermissions[ventana] || false;
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
    // Usar AuthService para limpiar todos los datos
    this.authService.logout();
    localStorage.removeItem('username'); // Por compatibilidad con código existente
    window.location.href = '/notes';
  }
}
