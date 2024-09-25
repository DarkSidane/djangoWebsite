
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('', include('home.urls')),  # Inclure les URLs de l'application 'home'
    path('admin/', admin.site.urls),
]

