import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { CommonModule } from '@angular/common';

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
import { ConfiguracionComponent } from './pages/configuracion/configuracion.component';
import { BitacoraComponent } from './pages/bitacora/bitacora.component';
import { LotesComponent } from './pages/lotes/lotes.component';
import { OrdenProduccionComponent } from './pages/ordenproduccion/ordenproduccion.component';
import { NotaSalidaComponent } from './pages/nota-salida/nota-salida.component';
import { PermisosComponent } from './pages/permisos/permisos.component';
import { AsignarPermisosComponent } from './pages/asignar-permisos/asignar-permisos.component';
import { PermisoAccionDirective } from './directives/permiso-accion.directive';

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
    ConfiguracionComponent,
    BitacoraComponent,
    LotesComponent,
    OrdenProduccionComponent,
    NotaSalidaComponent,
    PermisosComponent,
    AsignarPermisosComponent,
    PermisoAccionDirective,
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    CommonModule,
    FormsModule,
    HttpClientModule,
    BrowserAnimationsModule, // required animations module
    ToastrModule.forRoot(), // ToastrModule added
  ],
  
  bootstrap: [AppComponent],
})
export class AppModule {}
