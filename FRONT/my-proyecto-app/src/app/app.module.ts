import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';

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
import { BitacoraInterceptor } from './services_back/bitacora.interceptor';
import { LotesComponent } from './pages/lotes/lotes.component';
import { OrdenProduccionComponent } from './pages/ordenproduccion/ordenproduccion.component';

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
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,
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
