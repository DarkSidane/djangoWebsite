#!/bin/bash

# Créer le projet Django et l'application 'home'
django-admin startproject mysite
cd mysite
python3 manage.py startapp home

# Ajouter 'home' à INSTALLED_APPS dans mysite/settings.py
cd mysite

# S'assurer que 'home' est ajouté à INSTALLED_APPS
sed -i '' "/INSTALLED_APPS = \[/ a\\
    'home',  # Ajoutez votre application 'home' ici
" settings.py

# Ajouter STATICFILES_DIRS et configuration pour les messages à settings.py
echo "
STATIC_URL = '/static/'

import os
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'home/static')]

# Configuration pour les messages
from django.contrib.messages import constants as messages

MESSAGE_TAGS = {
    messages.ERROR: 'error',
    messages.SUCCESS: 'success',
}
" >> settings.py

# Ajouter les middlewares nécessaires pour les sessions, les messages et l'authentification
sed -i '' "/MIDDLEWARE = \[/ a\\
    'django.contrib.sessions.middleware.SessionMiddleware',\\
    'django.middleware.common.CommonMiddleware',\\
    'django.contrib.auth.middleware.AuthenticationMiddleware',\\
    'django.contrib.messages.middleware.MessageMiddleware',
" settings.py

# Ajouter le context processor pour les messages et l'authentification
sed -i '' "/'django.template.context_processors.debug',/ a\\
                    'django.template.context_processors.request',\\
                    'django.contrib.auth.context_processors.auth',\\
                    'django.contrib.messages.context_processors.messages',
" settings.py

# Modifier mysite/urls.py pour inclure les URLs de l'application 'home' et de l'admin
echo "
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('', include('home.urls')),  # Inclure les URLs de l'application 'home'
    path('admin/', admin.site.urls),  # Inclure les URLs de l'administration
]
" > urls.py

# Revenir au répertoire principal du projet
cd ..

# Créer home/urls.py
echo "
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('inscription/', views.registration, name='registration'),
    path('login/', views.login, name='login'),
    path('logout/', views.logout, name='logout'),
]
" > home/urls.py

# Créer home/views.py
echo "
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
            messages.error(request, \"Les mots de passe ne correspondent pas.\")
            return render(request, 'home/registration.html')

        if User.objects.filter(username=username).exists():
            messages.error(request, \"Le nom d'utilisateur existe déjà.\")
            return render(request, 'home/registration.html')

        if User.objects.filter(email=email).exists():
            messages.error(request, \"L'adresse e-mail est déjà utilisée.\")
            return render(request, 'home/registration.html')

        # Création de l'utilisateur
        user = User.objects.create_user(username=username, email=email, password=password)
        user.save()

        messages.success(request, \"Inscription réussie. Vous pouvez maintenant vous connecter.\")
        return redirect('index')

    return render(request, 'home/registration.html')

def login(request):
    if request.method == 'POST':
        username = request.POST.get('username').strip()
        password = request.POST.get('password')

        user = authenticate(request, username=username, password=password)
        if user is not None:
            auth_login(request, user)
            messages.success(request, f\"Bienvenue, {username}!\")
            return redirect('index')
        else:
            messages.error(request, \"Nom d'utilisateur ou mot de passe incorrect.\")
            return redirect('index')

    return redirect('index')

def logout(request):
    auth_logout(request)
    messages.success(request, \"Vous êtes maintenant déconnecté.\")
    return redirect('index')
" > home/views.py

# Créer le répertoire des templates
mkdir -p home/templates/home

# Créer home/templates/home/index.html
cat <<'EOF' > home/templates/home/index.html
<!DOCTYPE html>
<html lang="fr">
<head>
    {% load static %}
    <meta charset="UTF-8">
    <title>Page d'accueil</title>
    <link rel="stylesheet" type="text/css" href="{% static 'css/styles.css' %}">
</head>
<body>
    <!-- Affichage des messages -->
    {% if messages %}
        <ul class="messages">
            {% for message in messages %}
                <li class="{{ message.tags }}">{{ message }}</li>
            {% endfor %}
        </ul>
    {% endif %}

    {% if user.is_authenticated %}
        <h1>Bienvenue, {{ user.username }}!</h1>
        <button onclick="window.location.href='{% url 'logout' %}'">Se déconnecter</button>
    {% else %}
        <h1>Bienvenue, invité!</h1>
        <button id="loginBtn">Se connecter</button>
        <button onclick="window.location.href='{% url 'registration' %}'">S'inscrire</button>
    {% endif %}

    <!-- Popup de connexion -->
    <div id="loginPopup" class="popup">
        <div class="popup-content">
            <span class="close">&times;</span>
            <h2>Connexion</h2>
            <form action="{% url 'login' %}" method="post">
                {% csrf_token %}
                <label for="username">Utilisateur:</label>
                <input type="text" id="username" name="username" required>
                <label for="password">Mot de passe:</label>
                <input type="password" id="password" name="password" required>
                <button type="submit">Se connecter</button>
            </form>
        </div>
    </div>

    <script>
        // Script pour gérer le popup de connexion
        var popup = document.getElementById('loginPopup');
        var btn = document.getElementById('loginBtn');
        var span = document.getElementsByClassName('close')[0];

        if (btn) {
            btn.onclick = function() {
                popup.style.display = 'block';
            }
        }

        span.onclick = function() {
            popup.style.display = 'none';
        }

        window.onclick = function(event) {
            if (event.target == popup) {
                popup.style.display = 'none';
            }
        }
    </script>
</body>
</html>
EOF

# Créer home/templates/home/registration.html
cat <<'EOF' > home/templates/home/registration.html
<!DOCTYPE html>
<html lang="fr">
<head>
    {% load static %}
    <meta charset="UTF-8">
    <title>Inscription</title>
    <link rel="stylesheet" type="text/css" href="{% static 'css/styles.css' %}">
</head>
<body>
    <h1>Inscription</h1>

    <!-- Affichage des messages -->
    {% if messages %}
        <ul class="messages">
            {% for message in messages %}
                <li class="{{ message.tags }}">{{ message }}</li>
            {% endfor %}
        </ul>
    {% endif %}

    <form action="{% url 'registration' %}" method="post">
        {% csrf_token %}
        <label for="username">Nom d'utilisateur :</label>
        <input type="text" id="username" name="username" required>

        <label for="email">Adresse e-mail :</label>
        <input type="email" id="email" name="email" required>

        <label for="password">Mot de passe :</label>
        <input type="password" id="password" name="password" required>

        <label for="confirm_password">Confirmer le mot de passe :</label>
        <input type="password" id="confirm_password" name="confirm_password" required>

        <button type="submit">S'inscrire</button>
    </form>
</body>
</html>
EOF

# Créer le répertoire static/css et le fichier styles.css
mkdir -p home/static/css
cat <<'EOF' > home/static/css/styles.css
/* Styles CSS existants */
body {
    font-family: Arial, sans-serif;
    text-align: center;
    padding: 50px;
}

button {
    padding: 10px 20px;
    margin: 5px;
    font-size: 16px;
}

form {
    display: inline-block;
    text-align: left;
    margin-top: 20px;
}

label {
    display: block;
    margin-top: 10px;
}

input[type="text"],
input[type="email"],
input[type="password"] {
    width: 100%;
    padding: 8px;
    margin: 5px 0;
    box-sizing: border-box;
}

.messages {
    list-style-type: none;
    padding: 0;
}

.messages li {
    margin: 10px auto;
    padding: 10px;
    width: 50%;
    color: #fff;
    border-radius: 5px;
}

.messages li.error {
    background-color: #e74c3c;
}

.messages li.success {
    background-color: #2ecc71;
}

.popup {
    display: none; /* Masquer le popup par défaut */
    position: fixed;
    z-index: 1;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    overflow: auto;
    background-color: rgba(0,0,0,0.5); /* Fond noir avec opacité */
}

.popup-content {
    background-color: #fefefe;
    margin: 15% auto; /* 15% du haut, centré horizontalement */
    padding: 20px;
    border: 1px solid #888;
    width: 300px;
    position: relative;
}

.close {
    color: #aaa;
    position: absolute;
    top: 10px;
    right: 15px;
    font-size: 28px;
    font-weight: bold;
    cursor: pointer;
}

.popup-content button {
    width: 100%;
    padding: 10px;
    margin-top: 15px;
}
EOF

# Appliquer les migrations
python3 manage.py migrate

# Créer un superutilisateur pour accéder au panneau d'administration
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'adminpass')" | python3 manage.py shell

# Lancer le serveur de développement
python3 manage.py runserver
