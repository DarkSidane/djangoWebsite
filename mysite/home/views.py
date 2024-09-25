
from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login as auth_login, logout as auth_logout

def index(request):
    return render(request, 'home/index.html')

def registration(request):
    if request.method == 'POST':
        username = request.POST.get('username').strip()
        email = request.POST.get('email').strip()
        password = request.POST.get('password')
        confirm_password = request.POST.get('confirm_password')

        # Validation
        if password != confirm_password:
            messages.error(request, "Les mots de passe ne correspondent pas.")
            return render(request, 'home/registration.html')

        if User.objects.filter(username=username).exists():
            messages.error(request, "Le nom d'utilisateur existe déjà.")
            return render(request, 'home/registration.html')

        if User.objects.filter(email=email).exists():
            messages.error(request, "L'adresse e-mail est déjà utilisée.")
            return render(request, 'home/registration.html')

        # Création de l'utilisateur
        user = User.objects.create_user(username=username, email=email, password=password)
        user.save()

        messages.success(request, "Inscription réussie. Vous pouvez maintenant vous connecter.")
        return redirect('index')

    return render(request, 'home/registration.html')

def login(request):
    if request.method == 'POST':
        username = request.POST.get('username').strip()
        password = request.POST.get('password')

        user = authenticate(request, username=username, password=password)
        if user is not None:
            auth_login(request, user)
            messages.success(request, f"Bienvenue, {username}!")
            return redirect('index')
        else:
            messages.error(request, "Nom d'utilisateur ou mot de passe incorrect.")
            return redirect('index')

    return redirect('index')

def logout(request):
    auth_logout(request)
    messages.success(request, "Vous êtes maintenant déconnecté.")
    return redirect('index')

