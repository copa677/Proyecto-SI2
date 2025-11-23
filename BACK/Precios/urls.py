from django.urls import path
from . import views

urlpatterns = [
    # GET
    path('listar/', views.precios_list, name='precios-list'),
    path('precios/', views.precios_list, name='precios-list'),
    path('precios/all/', views.precios_list_all, name='precios-list-all'),
    path('precios/search/', views.precios_search, name='precios-search'),
    path('precios/<int:pk>/', views.precios_detail, name='precios-detail'),
    
    # POST
    path('precios/create/', views.precios_create, name='precios-create'),
    
    # PUT
    path('precios/update/<int:pk>/', views.precios_update, name='precios-update'),
    path('precios/activate/<int:pk>/', views.precios_activate, name='precios-activate'),
    
    # DELETE
    path('precios/delete/<int:pk>/', views.precios_delete, name='precios-delete'),
]