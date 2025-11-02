import { Component, OnInit } from '@angular/core';
import { LotesService } from '../../services_back/lotes.service';
import { Lote } from '../../../interface/lote';
import { MateriaPrima } from '../../../interface/materiaprima';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-lotes',
  templateUrl: './lotes.component.html',
  styleUrls: ['./lotes.component.css']
})
export class LotesComponent implements OnInit {
  lotes: Lote[] = [];
  materiasPrimas: MateriaPrima[] = [];
  selectedLote: Lote | null = null;
  showForm = false;
  showMateriaForm = false;
  formData: Partial<Lote> & { materiaInput?: string } = {};
  materiaFormData: Partial<MateriaPrima> = {};
  activeTab: 'lotes' | 'materias' = 'lotes';
  
  // Autocompletar
  filteredMaterias: MateriaPrima[] = [];
  showMateriaSuggestions = false;
  estadosLote = ['Pendiente', 'En Proceso', 'Aprobado', 'Rechazado'];
  filteredEstados: string[] = [];
  showEstadoSuggestions = false;

  constructor(
    private lotesService: LotesService,
    private toastr: ToastrService
  ) {}

  ngOnInit(): void {
    this.getLotes();
    this.getMateriasPrimas();
  }

  // ===========================
  //   CRUD DE LOTES
  // ===========================
  getLotes() {
    this.lotesService.getLotes().subscribe({
      next: (data: Lote[]) => (this.lotes = data),
      error: () => this.toastr.error('No se pudieron cargar los lotes', 'Error')
    });
  }

  getMateriasPrimas() {
    this.lotesService.getMateriasPrimas().subscribe({
      next: (data: MateriaPrima[]) => (this.materiasPrimas = data),
      error: () => this.toastr.error('No se pudieron cargar las materias primas', 'Error')
    });
  }

  selectLote(lote: Lote) {
    this.selectedLote = lote;
    this.showForm = false;
  }

  openForm(lote?: Lote) {
    this.showForm = true;
    this.formData = lote ? { ...lote } : {};
  }

  openMateriaForm(materia?: MateriaPrima) {
    this.showMateriaForm = true;
    this.materiaFormData = materia ? { ...materia } : {};
  }

  // ---------- Guardar Lote ----------
  saveLote() {
    if (this.formData.id_lote) {
      // Actualizar
      this.lotesService.actualizarLote(this.formData.id_lote, this.formData as Lote).subscribe({
        next: () => {
          this.toastr.success('Lote actualizado correctamente', 'Éxito');
          this.getLotes();
          this.showForm = false;
        },
        error: () => this.toastr.error('Error al actualizar el lote', 'Error')
      });
    } else {
      // Crear
      this.lotesService.insertarLote(this.formData as Lote).subscribe({
        next: () => {
          this.toastr.success('Lote creado correctamente', 'Éxito');
          this.getLotes();
          this.showForm = false;
        },
        error: () => this.toastr.error('Error al crear el lote', 'Error')
      });
    }
  }

  // ---------- Guardar Materia Prima ----------
  saveMateria() {
    if (this.materiaFormData.id_materia) {
      // Actualizar
      this.lotesService.actualizarMateriaPrima(this.materiaFormData.id_materia, this.materiaFormData as MateriaPrima).subscribe({
        next: () => {
          this.toastr.success('Materia prima actualizada correctamente', 'Éxito');
          this.getMateriasPrimas();
          this.showMateriaForm = false;
        },
        error: () => this.toastr.error('Error al actualizar la materia prima', 'Error')
      });
    } else {
      // Crear
      this.lotesService.insertarMateriaPrima(this.materiaFormData as MateriaPrima).subscribe({
        next: () => {
          this.toastr.success('Materia prima creada correctamente', 'Éxito');
          this.getMateriasPrimas();
          this.showMateriaForm = false;
        },
        error: () => this.toastr.error('Error al crear la materia prima', 'Error')
      });
    }
  }

  // ---------- Eliminar Lote ----------
  deleteLote(id?: number) {
    if (typeof id !== 'number') return;
    if (!confirm('¿Está seguro de eliminar este lote?')) return;

    this.lotesService.eliminarLote(id).subscribe({
      next: () => {
        this.toastr.success('Lote eliminado correctamente', 'Éxito');
        this.getLotes();
      },
      error: () => this.toastr.error('Error al eliminar el lote', 'Error')
    });
  }

  // ---------- Eliminar Materia ----------
  deleteMateria(id?: number) {
    if (typeof id !== 'number') return;
    if (!confirm('¿Está seguro de eliminar esta materia prima?')) return;

    this.lotesService.eliminarMateriaPrima(id).subscribe({
      next: () => {
        this.toastr.success('Materia prima eliminada correctamente', 'Éxito');
        this.getMateriasPrimas();
      },
      error: () => this.toastr.error('Error al eliminar la materia prima', 'Error')
    });
  }

  // ===========================
  //   UTILIDADES / AUTOCOMPLETAR
  // ===========================
  getMateriaNombre(id_materia: number): string {
    const materia = this.materiasPrimas.find(m => m.id_materia === id_materia);
    return materia ? materia.nombre : 'N/A';
  }

  onMateriaInput(value: any) {
    const searchValue = value ? value.toString().toLowerCase() : '';
    if (searchValue.length > 0) {
      this.filteredMaterias = this.materiasPrimas.filter(m => {
        const nombreMatch = m.nombre.toLowerCase().includes(searchValue);
        const idMatch = m.id_materia?.toString().includes(searchValue);
        return nombreMatch || idMatch;
      });
      this.showMateriaSuggestions = this.filteredMaterias.length > 0;
    } else {
      this.showMateriaSuggestions = false;
    }
  }

  selectMateria(materia: MateriaPrima) {
    this.formData.id_materia = materia.id_materia;
    this.formData.materiaInput = materia.nombre;
    this.showMateriaSuggestions = false;
  }

  onEstadoInput(value: string) {
    if (value && value.length > 0) {
      this.filteredEstados = this.estadosLote.filter(e =>
        e.toLowerCase().includes(value.toLowerCase())
      );
      this.showEstadoSuggestions = this.filteredEstados.length > 0;
    } else {
      this.showEstadoSuggestions = false;
    }
  }

  selectEstado(estado: string) {
    this.formData.estado = estado;
    this.showEstadoSuggestions = false;
  }
}
