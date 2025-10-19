import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable()
export class BitacoraInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    // Obtener el username y token del localStorage
    const username = localStorage.getItem('username');
    const token = localStorage.getItem('token');

    // Clonar el request para modificarlo
    let clonedReq = req;

    // Agregar el token JWT en el header Authorization si existe
    if (token) {
      clonedReq = clonedReq.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      });
    }

    // Agregar __bitacora_user__ en todas las peticiones si hay usuario
    if (username) {
      if (clonedReq.method === 'GET' || clonedReq.method === 'DELETE') {
        // Para GET/DELETE, agregar como parámetro de query especial
        const params = clonedReq.params.set('__bitacora_user__', username);
        clonedReq = clonedReq.clone({ params });
      } else {
        // Para POST/PUT/PATCH, agregar al body
        let body = clonedReq.body || {};
        body = { ...body, __bitacora_user__: username };
        clonedReq = clonedReq.clone({ body });
      }
    }

    return next.handle(clonedReq);
  }
}
