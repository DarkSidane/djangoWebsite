
from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth.hashers import make_password, check_password
import yaml
import os
from django.conf import settings

def index(request):
    return render(request, 'home/index.html')

def registration(request):
    if request.method == 'POST':
        username = request.POST.get('username').strip()
        email = request.POST.get('email').strip()
        password = request.POST.get('password')
        confirm_password = request.POST.get('confirm_password')

        # Validation simple
        if password != confirm_password:
            messages.error(request, "Les mots de passe ne correspondent pas.")
            return render(request, 'home/registration.html')

        # Chargement des utilisateurs existants
        users_file = os.path.join(settings.BASE_DIR, 'home', 'users.yaml')
        if os.path.exists(users_file):
            with open(users_file, 'r') as file:
                users = yaml.safe_load(file) or []
        else:
            users = []

        # Vérification si le nom d'utilisateur ou l'email existe déjà
        for user in users:
            if user['username'] == username:
                messages.error(request, "Le nom d'utilisateur existe déjà.")
                return render(request, 'home/registration.html')
            if user['email'] == email:
                messages.error(request, "L'adresse e-mail est déjà utilisée.")
                return render(request, 'home/registration.html')

        # Enregistrement du nouvel utilisateur avec mot de passe haché
        user_data = {
            'username': username,
            'email': email,
            'password': make_password(password)
        }
        users.append(user_data)

        with open(users_file, 'w') as file:
            yaml.dump(users, file)

        messages.success(request, "Inscription réussie. Vous pouvez maintenant vous connecter.")
        return redirect('index')

    return render(request, 'home/registration.html')

def login(request):
    if request.method == 'POST':
        username = request.POST.get('username').strip()
        password = request.POST.get('password')

        # Charger les utilisateurs existants
        users_file = os.path.join(settings.BASE_DIR, 'home', 'users.yaml')
        if os.path.exists(users_file):
            with open(users_file, 'r') as file:
                users = yaml.safe_load(file) or []
        else:
            users = []

        # Authentifier l'utilisateur
        user_found = False
        for user in users:
            if user['username'] == username:
                user_found = True
                if check_password(password, user['password']):
                    # Connexion réussie
                    request.session['username'] = username
                    messages.success(request, f"Bienvenue, {username}!")
                    return redirect('index')
                else:
                    break  # Mot de passe incorrect

        # Si l'authentification échoue
        if not user_found:
            messages.error(request, "Nom d'utilisateur incorrect.")
        else:
            messages.error(request, "Mot de passe incorrect.")
        return redirect('index')

    return redirect('index')

def logout(request):
    try:
        del request.session['username']
    except KeyError:
        pass
    messages.success(request, "Vous êtes maintenant déconnecté.")
    return redirect('index')

