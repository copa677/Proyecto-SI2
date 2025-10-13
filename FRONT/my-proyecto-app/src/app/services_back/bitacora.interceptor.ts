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

    // Solo agregar el usuario de bitácora en peticiones que modifican datos
    const metodosConBody = ['POST', 'PUT', 'PATCH'];
    
    if (username && metodosConBody.includes(req.method)) {
      // Clonar el request y agregar __bitacora_user__ al body
      // Usamos un nombre especial para evitar conflictos con campos del usuario
      let body = clonedReq.body || {};
      body = { ...body, __bitacora_user__: username };
      
      clonedReq = clonedReq.clone({
        body: body
      });
    }

    return next.handle(clonedReq);
  }
}
