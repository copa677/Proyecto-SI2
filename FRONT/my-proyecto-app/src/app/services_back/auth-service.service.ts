// auth.service.ts
import { Injectable } from '@angular/core';
import { jwtDecode } from 'jwt-decode';
import { Router } from '@angular/router';
import { ToastrService } from 'ngx-toastr';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private tokenCheckInterval = 60000; // 1 minuto

  constructor(private router: Router, private toastr: ToastrService) {
    this.startTokenWatch();
  }

  private startTokenWatch(): void {
    setInterval(() => {
      this.checkToken();
    }, this.tokenCheckInterval);
  }

  checkToken(): void {
    const token = localStorage.getItem('token');
    if (token) {
      try {
        const decoded = jwtDecode(token) as { exp: number };
        if (decoded.exp * 1000 < Date.now()) {
          this.handleExpiredToken();
        }
      } catch (e) {
        this.handleExpiredToken();
      }
    }
  }

  private handleExpiredToken(): void {
    localStorage.removeItem('token');
    this.toastr.error('Sesión expirada', '', {
      positionClass: 'toast-bottom-right',
      timeOut: 3000
    });
    this.router.navigate(['/login']);
  }
}