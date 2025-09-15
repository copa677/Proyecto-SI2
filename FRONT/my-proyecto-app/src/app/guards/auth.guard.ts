import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';

export const authGuard: CanActivateFn = (route, state) => {
  const router = inject(Router);
  const token = localStorage.getItem('token');

  if (token) {
    return true; // ✅ tiene token → pasa
  }

  // ❌ no hay token → redirige al login
  return router.parseUrl('/notes');
};