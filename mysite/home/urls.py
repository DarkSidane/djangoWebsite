
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('inscription/', views.registration, name='registration'),
    path('login/', views.login, name='login'),
    path('logout/', views.logout, name='logout'),
]

