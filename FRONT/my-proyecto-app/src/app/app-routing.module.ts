import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { NotesComponent } from './pages/notes/notes.component';
import { MenuComponent } from './pages/menu/menu.component';
import { UsuariosComponent } from './pages/usuarios/usuarios.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { PersonalComponent } from './pages/personal/personal.component';
import { AsistenciaComponent } from './pages/asistencia/asistencia.component';
import { BitacoraComponent } from './pages/bitacora/bitacora.component';
import { authGuard } from './guards/auth.guard';
import { PermissionGuard } from './guards/permission.guard';
import { RoleGuard } from './guards/role.guard';
import { LotesComponent } from './pages/lotes/lotes.component';
import { OrdenProduccionComponent } from './pages/ordenproduccion/ordenproduccion.component';
import { NotaSalidaComponent } from './pages/nota-salida/nota-salida.component';
import { PermisosComponent } from './pages/permisos/permisos.component';
import { AsignarPermisosComponent } from './pages/asignar-permisos/asignar-permisos.component';
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
import { ClienteDashboardComponent } from './pages/cliente-dashboard/cliente-dashboard.component';
import { ClientePedidosComponent } from './pages/cliente-pedidos/cliente-pedidos.component';
import { ClienteFacturasComponent } from './pages/cliente-facturas/cliente-facturas.component';
import { FacturasComponent } from './pages/facturas/facturas.component';

const routes: Routes = [
  { path: 'registro-cliente', component: RegistroClienteComponent },
  // Rutas para el portal del cliente

  {
    path: 'menu', component: MenuComponent,
    canActivate: [authGuard], 
    children: [
      { 
        path: 'usuarios', 
        component: UsuariosComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'gestionar_usuarios'
        }
      },
      { 
        path: 'clientes', 
        component: ClienteComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'gestionar_clientes'
        }
      },
      { 
        path: 'clientes', 
        component: ClienteComponent,
        canActivate: [PermissionGuard],
        data: { ventana: 'Clientes', accion: 'ver' }
      },
      { 
        path: 'dashboard', 
        component: DashboardComponent 
        // Dashboard sin restricción - todos pueden verlo
      },
      { 
        path: 'personal', 
        component: PersonalComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'gestionar_personal'
        }
      },
      { 
        path: 'asistencia', 
        component: AsistenciaComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'gestionar_asistencia'
        }
      },
      { 
        path: 'turnos', 
        component: TurnosComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'gestionar_turnos'
        }
      },
      { 
        path: 'bitacora', 
        component: BitacoraComponent,
        canActivate: [RoleGuard],
        data: { 
          roles: ['Administrador', 'admin'],
          permission: 'ver_bitacora' // Permiso granular
        }
      },
      { 
        path: 'lotes', 
        component: LotesComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'ver_lotes'
        }
      },
      { 
        path: 'inventario', 
        component: InventarioComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'ver_inventario'
        }
      },
      { 
        path: 'ordenproduccion', 
        component: OrdenProduccionComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'ver_ordenes'
        }
      },
      { 
        path: 'trazabilidad', 
        component: TrazabilidadComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'ver_trazabilidad'
        }
      },
      { 
        path: 'control-calidad', 
        component: ControlCalidadComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'ver_calidad'
        }
      },
      { 
        path: 'nota-salida', 
        component: NotaSalidaComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'gestionar_notas_salida'
        }
      },
      { 
        path: 'permisos', 
        component: PermisosComponent,
        canActivate: [RoleGuard],
        data: { 
          roles: ['Administrador', 'admin'],
          permission: 'gestionar_permisos'
        }
      },
      { 
        path: 'asignar-permisos', 
        component: AsignarPermisosComponent,
        canActivate: [RoleGuard],
        data: { 
          roles: ['Administrador', 'admin'],
          permission: 'asignar_permisos'
        }
      },
      {
        path: 'reporte-inventario',
        component: ReporteInventarioComponent,
        canActivate: [RoleGuard],
        data: { 
          roles: ['Administrador', 'Supervisor'],
          permission: 'ver_reportes'
        }
      },
      {
        path: 'reporte-produccion',
        component: ReporteProduccionComponent,
        canActivate: [RoleGuard],
        data: { 
          roles: ['Administrador', 'Supervisor'],
          permission: 'ver_reportes'
        }
      },
      {
        path: 'reporte-ventas',
        component: ReporteVentasComponent,
        canActivate: [RoleGuard],
        data: { 
          roles: ['Administrador', 'Supervisor'],
          permission: 'ver_reportes'
        }
      },
      { 
        path: 'pedidos', 
        component: PedidosComponent,
        canActivate: [RoleGuard],
        data: { 
          permission: 'gestionar_pedidos'
        }
      },
      { 
        path: 'pedido-form', 
        component: PedidoFormComponent,
        canActivate: [authGuard]
      },
      { 
        path: 'pedido-form/:id', 
        component: PedidoFormComponent,
        canActivate: [authGuard]
      },
      { 
        path: 'pedido-detalle/:id', 
        component: PedidoDetalleComponent,
        canActivate: [authGuard]
      },
      { 
        path: 'reportes-ia', 
        component: ReportesIAComponent,
        canActivate: [RoleGuard],
        data: { 
          roles: ['Administrador', 'Supervisor'],
          permission: 'ver_reportes'
        }
      },
      // Ruta de facturas sin permisos específicos
      { 
        path: 'facturas', 
        component: FacturasComponent,
        canActivate: [authGuard] // Solo requiere autenticación, sin permisos específicos
      },
    ]
  },
  // Portal del Cliente
  {
    path: 'cliente',
    canActivate: [authGuard],
    children: [
      {
        path: 'tienda', // Catálogo de productos (principal)
        component: ClientePedidosComponent
      },
      {
        path: 'dashboard',
        component: ClienteDashboardComponent
      },
      {
        path: 'pedidos', // Alias para la tienda
        component: ClientePedidosComponent
      },
      {
        path: 'facturas',
        component: ClienteFacturasComponent
      },
      {
        path: 'pedidos/:id', // Para ver el detalle de un pedido específico
        component: PedidoDetalleComponent
      },
      { path: '', redirectTo: 'tienda', pathMatch: 'full' } // Redirige a tienda por defecto
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
