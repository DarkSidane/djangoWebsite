
from django.shortcuts import render

def index(request):
    return render(request, 'home/index.html')

def registration(request):
    return render(request, 'home/registration.html')

