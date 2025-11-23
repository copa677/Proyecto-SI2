// src/app/services/auth.service.ts
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  constructor() { }

  // Guardar información del usuario al iniciar sesión
  setUserData(token: string, tipo_usuario: string, name_user: string, email: string, rol?: string): void {
    localStorage.setItem('token', token);
    localStorage.setItem('userRole', rol || tipo_usuario); // Usar el rol real si está disponible
    localStorage.setItem('tipoUsuario', tipo_usuario); // Guardar también el tipo base
    localStorage.setItem('userName', name_user);
    localStorage.setItem('userEmail', email);
  }

  // Obtener el rol del usuario
  getUserRole(): string {
    return localStorage.getItem('userRole') || '';
  }

  // Obtener el nombre del usuario
  getUserName(): string {
    return localStorage.getItem('userName') || '';
  }

  // Obtener el email del usuario
  getUserEmail(): string {
    return localStorage.getItem('userEmail') || '';
  }

  // Obtener el token
  getToken(): string {
    return localStorage.getItem('token') || '';
  }

  // Verificar si el usuario está autenticado
  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  // Verificar si el usuario tiene un rol específico
  hasRole(role: string): boolean {
    return this.getUserRole() === role;
  }

  // Verificar si el usuario tiene alguno de los roles especificados
  hasAnyRole(roles: string[]): boolean {
    const userRole = this.getUserRole();
    return roles.includes(userRole);
  }

  // Cerrar sesión
  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('userRole');
    localStorage.removeItem('tipoUsuario');
    localStorage.removeItem('userName');
    localStorage.removeItem('userEmail');
  }

  // Verificar si es administrador (acepta 'admin' y 'Administrador')
  isAdmin(): boolean {
    const role = this.getUserRole();
    return role === 'Administrador' || role === 'admin';
  }

  // Verificar si es operario
  isOperario(): boolean {
    return this.getUserRole() === 'Operario';
  }

  // Verificar si es supervisor
  isSupervisor(): boolean {
    return this.getUserRole() === 'Supervisor';
  }
}
