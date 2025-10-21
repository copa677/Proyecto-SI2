import { Component, OnInit } from '@angular/core';
import { InventarioService } from '../../services_back/inventario.service';
import { LotesService } from '../../services_back/lotes.service';
import { Inventario } from '../../inventario.interface';
import { MateriaPrima } from '../../../interface/materiaprima';
import { Lote } from '../../../interface/lote';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-inventario',
  templateUrl: './inventario.component.html',
  styleUrls: ['./inventario.component.css']
})
export class InventarioComponent implements OnInit {
  inventarios: Inventario[] = [];
  selectedInventario: Inventario | null = null;
  showForm = false;
  formData: Partial<Inventario> & { loteInput?: string } = {
    id_inventario: undefined,
    nombre_materia_prima: '',
    cantidad_actual: undefined,
    unidad_medida: '',
    ubicacion: '',
    estado: '',
    fecha_actualizacion: '',
    id_lote: undefined,
    loteInput: ''
  };
  searchTerm = '';
  modalVisible = false;
  trazabilidad: any[] = [];
  
  // Listas para autocompletar
  materiasPrimas: MateriaPrima[] = [];
  lotes: Lote[] = [];
  filteredMateriasPrimas: MateriaPrima[] = [];
  filteredLotes: Lote[] = [];
  showMateriaSuggestions = false;
  showLoteSuggestions = false;
  
  // Opciones para otros campos
  unidadesMedida = ['kg', 'g', 'l', 'ml', 'm', 'cm', 'unidad', 'caja', 'paquete'];
  ubicaciones = ['Almacén A', 'Almacén B', 'Almacén C', 'Zona de Corte', 'Zona de Costura'];
  filteredUnidades: string[] = [];
  filteredUbicaciones: string[] = [];
  showUnidadSuggestions = false;
  showUbicacionSuggestions = false;

  constructor(
    private inventarioService: InventarioService,
    private lotesService: LotesService,
    private toastr: ToastrService
  ) {}

  ngOnInit(): void {
    this.getInventarios();
    this.loadMateriasPrimas();
    this.loadLotes();
  }

  getInventarios() {
    this.inventarioService.getInventarios().subscribe(
      (data: Inventario[]) => {
        this.inventarios = data;
      },
      error => {
        console.error('Error al obtener inventarios:', error);
        this.toastr.error('No se pudieron cargar los inventarios', 'Error');
      }
    );
  }
  
  loadMateriasPrimas() {
    this.lotesService.getMateriasPrimas().subscribe(
      (data: MateriaPrima[]) => {
        this.materiasPrimas = data;
      },
      error => {
        console.error('Error al cargar materias primas:', error);
        this.toastr.error('No se pudieron cargar las materias primas', 'Error');
      }
    );
  }
  
  loadLotes() {
    this.lotesService.getLotes().subscribe(
      (data: Lote[]) => {
        this.lotes = data;
      },
      error => {
        console.error('Error al cargar lotes:', error);
        this.toastr.error('No se pudieron cargar los lotes', 'Error');
      }
    );
  }

  get filteredInventarios() {
    if (!this.searchTerm) return this.inventarios;
    return this.inventarios.filter(inv => 
      inv.nombre_materia_prima?.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
      inv.unidad_medida?.toLowerCase().includes(this.searchTerm.toLowerCase())
    );
  }

  selectInventario(inventario: Inventario) {
    this.selectedInventario = inventario;
    this.showForm = false;
  }

  openForm(inventario?: Inventario) {
    this.showForm = true;
    if (inventario) {
      // Asegurarse que cantidad_actual sea number
      let cantidad: number | undefined = undefined;
      if (typeof inventario.cantidad_actual === 'string') {
        cantidad = parseFloat((inventario.cantidad_actual as string).replace(',', '.'));
      } else if (typeof inventario.cantidad_actual === 'number') {
        cantidad = inventario.cantidad_actual;
      }
      this.formData = { ...inventario, cantidad_actual: cantidad };
    } else {
      this.formData = {
        nombre_materia_prima: '',
        cantidad_actual: undefined,
        unidad_medida: '',
        ubicacion: '',
        estado: 'Activo',
        fecha_actualizacion: '',
        id_lote: undefined
      };
    }
  }

  closeForm() {
    this.showForm = false;
    this.formData = {};
    }

    verTrazabilidad(inventario: Inventario) {
      // Llama al servicio para obtener la trazabilidad del lote
      this.inventarioService.getTrazabilidadPorLote(inventario.id_lote).subscribe(
        (data: any[]) => {
          this.trazabilidad = data;
          this.modalVisible = true;
          if (data.length === 0) {
            this.toastr.info('No hay trazabilidad disponible para este lote', 'Información');
          }
        },
        error => {
          this.trazabilidad = [];
          this.modalVisible = true;
          this.toastr.error('Error al cargar la trazabilidad', 'Error');
        }
      );
    }

  saveInventario() {
    console.log('saveInventario llamado');
    console.log('formData antes de procesar:', this.formData);
    
    // Asegurar que cantidad_actual sea número y no string con coma
    // Normalizar cantidad_actual para que siempre sea number o undefined
    if (typeof this.formData.cantidad_actual === 'string') {
      const normalizado = (this.formData.cantidad_actual as string).replace(',', '.');
      this.formData.cantidad_actual = normalizado === '' ? undefined : parseFloat(normalizado);
    }
    
    console.log('formData después de normalizar:', this.formData);
    
  if (this.formData.id_inventario) {
      // Actualizar inventario existente
      const data: Partial<Inventario> = { ...this.formData };
      console.log('Actualizando inventario con ID:', this.formData.id_inventario);
      console.log('Datos a enviar:', data);
      
      this.inventarioService.updateInventario(this.formData.id_inventario, data).subscribe(
        (response) => {
          console.log('Inventario actualizado exitosamente:', response);
          this.toastr.success('Inventario actualizado correctamente', 'Éxito');
          this.getInventarios();
          this.closeForm();
        },
        error => {
          console.error('Error al actualizar inventario:', error);
          this.toastr.error('Error al actualizar inventario', 'Error');
        }
      );
    } else {
      // Crear nuevo inventario
      // Solo enviar los campos requeridos por el backend
      const selectedLote = this.lotes.find(l => l.id_lote === this.formData.id_lote);
      if (!selectedLote) {
        alert('Debes seleccionar un lote válido.');
        return;
      }
      // Si no hay fecha_actualizacion, usar la fecha y hora actual en formato ISO
      let fechaActual = this.formData.fecha_actualizacion;
      if (!fechaActual || fechaActual === '') {
        fechaActual = new Date().toISOString();
      }
      const data = {
        cod_lote: selectedLote.codigo_lote,
        unidad_medida: this.formData.unidad_medida,
        ubicacion: this.formData.ubicacion,
        estado: this.formData.estado,
        fecha_actualizacion: fechaActual
      };
      console.log('Creando nuevo inventario');
      console.log('Datos a enviar:', data);
      this.inventarioService.createInventario(data).subscribe(
        (response) => {
          console.log('Inventario creado exitosamente:', response);
          this.toastr.success('Inventario creado correctamente', 'Éxito');
          this.getInventarios();
          this.closeForm();
        },
        error => {
          console.error('Error al crear inventario:', error);
          console.error('Detalles del error:', error.error);
          this.toastr.error('Error al crear inventario', 'Error');
        }
      );
    }
  }

  deleteInventario(id: number) {
    if (confirm('¿Está seguro de eliminar este item del inventario?')) {
      this.inventarioService.deleteInventario(id).subscribe(
        () => {
          this.toastr.success('Inventario eliminado correctamente', 'Éxito');
          this.getInventarios();
          if (this.selectedInventario?.id_inventario === id) {
            this.selectedInventario = null;
          }
        },
        error => {
          console.error('Error al eliminar inventario:', error);
          this.toastr.error('Error al eliminar inventario', 'Error');
        }
      );
    }
  }

  getEstadoClass(estado: string): string {
    switch(estado) {
      case 'Disponible': return 'bg-green-100 text-green-800';
      case 'Stock Bajo': return 'bg-yellow-100 text-yellow-800';
      case 'Agotado': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  }
  
  // Métodos de autocompletar para Materia Prima
  onMateriaPrimaInput(value: string) {
    if (value && value.length > 0) {
      this.filteredMateriasPrimas = this.materiasPrimas.filter(m => 
        m.nombre.toLowerCase().includes(value.toLowerCase())
      );
      this.showMateriaSuggestions = this.filteredMateriasPrimas.length > 0;
    } else {
      this.showMateriaSuggestions = false;
    }
  }
  
  selectMateriaPrima(materia: MateriaPrima) {
    this.formData.nombre_materia_prima = materia.nombre;
    this.showMateriaSuggestions = false;
  }
  
  // Métodos de autocompletar para Lote
  onLoteInput(value: any) {
    const searchValue = value ? value.toString().toLowerCase() : '';
    if (searchValue && searchValue.length > 0) {
      this.filteredLotes = this.lotes.filter(l => {
        const codigoMatch = l.codigo_lote.toLowerCase().includes(searchValue);
        const idMatch = l.id_lote?.toString().includes(searchValue);
        return codigoMatch || idMatch;
      });
      this.showLoteSuggestions = this.filteredLotes.length > 0;
    } else {
      this.showLoteSuggestions = false;
    }
  }
  
  selectLote(lote: Lote) {
  this.formData.id_lote = lote.id_lote;
  this.formData.loteInput = lote.codigo_lote;
  // Autocompletar el nombre de la materia prima asociada al lote
  const materia = this.materiasPrimas.find(m => m.id_materia === lote.id_materia);
  this.formData.nombre_materia_prima = materia ? materia.nombre : '';
  // Autocompletar la cantidad con la cantidad del lote
  this.formData.cantidad_actual = lote.cantidad;
  this.showLoteSuggestions = false;
  }
  
  // Métodos de autocompletar para Unidad de Medida
  onUnidadInput(value: string) {
    if (value && value.length > 0) {
      this.filteredUnidades = this.unidadesMedida.filter(u => 
        u.toLowerCase().includes(value.toLowerCase())
      );
      this.showUnidadSuggestions = this.filteredUnidades.length > 0;
    } else {
      this.showUnidadSuggestions = false;
    }
  }
  
  selectUnidad(unidad: string) {
    this.formData.unidad_medida = unidad;
    this.showUnidadSuggestions = false;
  }
  
  // Métodos de autocompletar para Ubicación
  onUbicacionInput(value: string) {
    if (value && value.length > 0) {
      this.filteredUbicaciones = this.ubicaciones.filter(u => 
        u.toLowerCase().includes(value.toLowerCase())
      );
      this.showUbicacionSuggestions = this.filteredUbicaciones.length > 0;
    } else {
      this.showUbicacionSuggestions = false;
    }
  }
  
  selectUbicacion(ubicacion: string) {
    this.formData.ubicacion = ubicacion;
    this.showUbicacionSuggestions = false;
  }
}
