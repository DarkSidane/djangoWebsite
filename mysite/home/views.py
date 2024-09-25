
from django.shortcuts import render, redirect
from django.contrib import messages
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

        # Enregistrement du nouvel utilisateur
        user_data = {
            'username': username,
            'email': email,
            'password': password  # Attention : les mots de passe devraient être hachés
        }
        users.append(user_data)

        with open(users_file, 'w') as file:
            yaml.dump(users, file)

        messages.success(request, "Inscription réussie. Vous pouvez maintenant vous connecter.")
        return redirect('index')

    return render(request, 'home/registration.html')

