import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http'; // ⬅️ AÑADE ESTO

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
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,
    HttpClientModule, // ⬅️ AÑADIDO
  ],
  providers: [],
  bootstrap: [AppComponent],
})
export class AppModule {}
