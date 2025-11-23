import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { ClientePedidosComponent } from './pages/cliente-pedidos/cliente-pedidos.component';
import { ClienteFacturasComponent } from './pages/cliente-facturas/cliente-facturas.component';
import { ClienteDashboardComponent } from './pages/cliente-dashboard/cliente-dashboard.component';
import { ReactiveFormsModule } from '@angular/forms';

import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { ToastrModule } from 'ngx-toastr';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { NotesComponent } from './pages/notes/notes.component';
import { HeaderComponent } from './components/header/header.component';
import { MenuComponent } from './pages/menu/menu.component';
import { UsuariosComponent } from './pages/usuarios/usuarios.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { PersonalComponent } from './pages/personal/personal.component';
import { AsistenciaComponent } from './pages/asistencia/asistencia.component';
import { BitacoraComponent } from './pages/bitacora/bitacora.component';
import { BitacoraInterceptor } from './services_back/bitacora.interceptor';
import { LotesComponent } from './pages/lotes/lotes.component';
import { OrdenProduccionComponent } from './pages/ordenproduccion/ordenproduccion.component';
import { NotaSalidaComponent } from './pages/nota-salida/nota-salida.component';
import { PermisosComponent } from './pages/permisos/permisos.component';
import { AsignarPermisosComponent } from './pages/asignar-permisos/asignar-permisos.component';
import { PermisoAccionDirective } from './directives/permiso-accion.directive';
import { CanDoDirective } from './directives/can-do.directive';
import { TurnosComponent } from './pages/turnos/turnos.component';
import { InventarioComponent } from './pages/inventario/inventario.component';
import { ControlCalidadComponent } from './pages/control-calidad/control-calidad.component';
import { TrazabilidadComponent } from './pages/trazabilidad/trazabilidad.component';
import { ClienteComponent } from './pages/cliente/cliente.component';
import { ReporteInventarioComponent } from './pages/reporte-inventario/reporte-inventario.component';
import { ReporteProduccionComponent } from './pages/reporte-produccion/reporte-produccion.component';
import { ReporteVentasComponent } from './pages/reporte-ventas/reporte-ventas.component';
import { PedidosComponent } from './pages/pedidos/pedidos.component';
import { PedidoFormComponent } from './pages/pedido-form/pedido-form.component';
import { PedidoDetalleComponent } from './pages/pedido-detalle/pedido-detalle.component';
import { ReportesIAComponent } from './pages/reportesIA/reportes-ia.component';
import { RegistroClienteComponent } from './pages/registro-cliente/registro-cliente.component';

@NgModule({
  declarations: [
    AppComponent,
    NotesComponent,
    HeaderComponent,
    MenuComponent,
    UsuariosComponent,
    DashboardComponent,
    PersonalComponent,
    AsistenciaComponent,
    BitacoraComponent,
    LotesComponent,
    OrdenProduccionComponent,
    NotaSalidaComponent,
    PermisosComponent,
    AsignarPermisosComponent,
    PermisoAccionDirective,
    CanDoDirective,
    TurnosComponent,
    InventarioComponent,
    ControlCalidadComponent,
    TrazabilidadComponent,
    ClienteComponent,
    PedidosComponent,
    PedidoFormComponent,
    PedidoDetalleComponent,
    ReportesIAComponent,
    RegistroClienteComponent,
    ClientePedidosComponent,
    ClienteFacturasComponent,
    ClienteDashboardComponent,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    HttpClientModule,
    BrowserAnimationsModule, // required animations module
    ToastrModule.forRoot(), // ToastrModule added
  ],
  providers: [
    {
      provide: HTTP_INTERCEPTORS,
      useClass: BitacoraInterceptor,
      multi: true
    }
  ],
  bootstrap: [AppComponent],
})
export class AppModule {}
