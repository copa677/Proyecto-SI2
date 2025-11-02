import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable()
export class BitacoraInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const username = localStorage.getItem('username');
    const token = localStorage.getItem('token');

    let clonedReq = req;

    // 🧠 Agregar token JWT si existe
    if (token) {
      clonedReq = clonedReq.clone({
        setHeaders: { Authorization: `Bearer ${token}` }
      });
    }

    // 🧠 Agregar __bitacora_user__ solo si hay username
    if (username) {
      if (clonedReq.method === 'GET' || clonedReq.method === 'DELETE') {
        // Para GET/DELETE, agregarlo como parámetro de URL
        const params = clonedReq.params.set('__bitacora_user__', username);
        clonedReq = clonedReq.clone({ params });

      } else if (clonedReq.body instanceof FormData) {
        // ✅ Si es FormData (como en tu restore), agrégalo directamente
        const formData = clonedReq.body;
        formData.append('__bitacora_user__', username);
        clonedReq = clonedReq.clone({ body: formData });

      } else {
        // ✅ Para JSON normales
        const body = { ...(clonedReq.body || {}), __bitacora_user__: username };
        clonedReq = clonedReq.clone({ body });
      }
    }

    return next.handle(clonedReq);
  }
}
