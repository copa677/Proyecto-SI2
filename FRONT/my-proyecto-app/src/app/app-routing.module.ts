import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { NotesComponent } from './pages/notes/notes.component';
import { MenuComponent } from './pages/menu/menu.component';
import { UsuariosComponent } from './pages/usuarios/usuarios.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { PersonalComponent } from './pages/personal/personal.component';
import { AsistenciaComponent } from './pages/asistencia/asistencia.component';
import { ConfiguracionComponent } from './pages/configuracion/configuracion.component';
import { BitacoraComponent } from './pages/bitacora/bitacora.component';
import { authGuard } from './guards/auth.guard';
import { PermissionGuard } from './guards/permission.guard';
import { LotesComponent } from './pages/lotes/lotes.component';
import { OrdenProduccionComponent } from './pages/ordenproduccion/ordenproduccion.component';
import { NotaSalidaComponent } from './pages/nota-salida/nota-salida.component';
import { PermisosComponent } from './pages/permisos/permisos.component';
import { AsignarPermisosComponent } from './pages/asignar-permisos/asignar-permisos.component';
import { TurnosComponent } from './pages/turnos/turnos.component';
import { InventarioComponent } from './pages/inventario/inventario.component';
import { ControlCalidadComponent } from './pages/control-calidad/control-calidad.component';
import { TrazabilidadComponent } from './pages/trazabilidad/trazabilidad.component';
import { ReporteInventarioComponent } from './pages/reporte-inventario/reporte-inventario.component';
import { ReporteProduccionComponent } from './pages/reporte-produccion/reporte-produccion.component';
import { ReporteVentasComponent } from './pages/reporte-ventas/reporte-ventas.component';


const routes: Routes = [
  {
    path: 'menu', component: MenuComponent,
    canActivate: [authGuard], 
    children: [
      { 
        path: 'usuarios', 
        component: UsuariosComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Usuarios', accion: 'ver' }
      },
      { 
        path: 'dashboard', 
        component: DashboardComponent 
        // Dashboard sin restricción - todos pueden verlo
      },
      { 
        path: 'personal', 
        component: PersonalComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Personal', accion: 'ver' }
      },
      { 
        path: 'asistencia', 
        component: AsistenciaComponent 
        // Asistencia sin restricción por ahora
      },
      { 
        path: 'turnos', 
        component: TurnosComponent 
        // Turnos sin restricción por ahora
      },
      { 
        path: 'bitacora', 
        component: BitacoraComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Bitacora', accion: 'ver' }
      },
      { 
        path: 'configuracion', 
        component: ConfiguracionComponent 
      },
      { 
        path: 'lotes', 
        component: LotesComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Lotes', accion: 'ver' }
      },
      { 
        path: 'inventario', 
        component: InventarioComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Inventario', accion: 'ver' }
      },
      { 
        path: 'ordenproduccion', 
        component: OrdenProduccionComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'OrdenProduccion', accion: 'ver' }
      },
      { 
        path: 'trazabilidad', 
        component: TrazabilidadComponent 
        // Trazabilidad sin restricción por ahora
      },
      { 
        path: 'control-calidad', 
        component: ControlCalidadComponent 
        // Control de calidad sin restricción por ahora
      },
      { 
        path: 'nota-salida', 
        component: NotaSalidaComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'NotaSalida', accion: 'ver' }
      },
      { 
        path: 'permisos', 
        component: PermisosComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Reportes', accion: 'ver' }
      },
      { 
        path: 'asignar-permisos', 
        component: AsignarPermisosComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Usuarios', accion: 'editar' }
      },
      {
        path: 'reporte-inventario',
        component: ReporteInventarioComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Reportes', accion: 'ver' }
      },
      {
        path: 'reporte-produccion',
        component: ReporteProduccionComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Reportes', accion: 'ver' }
      },
      {
        path: 'reporte-ventas',
        component: ReporteVentasComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Reportes', accion: 'ver' }
      },
    ]
  },
  { path: 'notes', component: NotesComponent },
  { path: '', redirectTo: 'notes', pathMatch: 'full' },

];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
