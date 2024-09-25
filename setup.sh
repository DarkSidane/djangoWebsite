#!/bin/bash

# Créer le projet Django et l'application 'home'
django-admin startproject mysite
cd mysite
python3 manage.py startapp home

# Ajouter 'home' à INSTALLED_APPS dans mysite/settings.py
cd mysite
sed -i '' "/INSTALLED_APPS = \[/ a\\
    'home',  # Ajoutez votre application 'home' ici
" settings.py

# Ajouter 'django.contrib.messages' et 'django.contrib.sessions' à INSTALLED_APPS
sed -i '' "/'django.contrib.staticfiles',/ a\\
    'django.contrib.messages',\\
    'django.contrib.sessions',
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

# Ajouter les middlewares nécessaires pour les sessions et les messages
sed -i '' "/MIDDLEWARE = \[/ a\\
    'django.contrib.sessions.middleware.SessionMiddleware',\\
    'django.middleware.common.CommonMiddleware',\\
    'django.contrib.messages.middleware.MessageMiddleware',
" settings.py

# Ajouter le context processor pour les messages
sed -i '' "/'django.template.context_processors.debug',/ a\\
                    'django.contrib.messages.context_processors.messages',
" settings.py

# Modifier mysite/urls.py pour inclure les URLs de l'application 'home'
echo "
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('', include('home.urls')),  # Inclure les URLs de l'application 'home'
    path('admin/', admin.site.urls),
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
            messages.error(request, \"Les mots de passe ne correspondent pas.\")
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
                messages.error(request, \"Le nom d'utilisateur existe déjà.\")
                return render(request, 'home/registration.html')
            if user['email'] == email:
                messages.error(request, \"L'adresse e-mail est déjà utilisée.\")
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

        messages.success(request, \"Inscription réussie. Vous pouvez maintenant vous connecter.\")
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
                    messages.success(request, f\"Bienvenue, {username}!\")
                    return redirect('index')
                else:
                    break  # Mot de passe incorrect

        # Si l'authentification échoue
        if not user_found:
            messages.error(request, \"Nom d'utilisateur incorrect.\")
        else:
            messages.error(request, \"Mot de passe incorrect.\")
        return redirect('index')

    return redirect('index')

def logout(request):
    try:
        del request.session['username']
    except KeyError:
        pass
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

    {% if request.session.username %}
        <h1>Bienvenue, {{ request.session.username }}!</h1>
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

# Appliquer les migrations (même si non utilisées pour cette page)
python3 manage.py migrate

# Lancer le serveur de développement
python3 manage.py runserver
