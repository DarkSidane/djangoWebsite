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

# Ajouter STATICFILES_DIRS à settings.py
echo "
STATIC_URL = '/static/'

import os
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'home/static')]
" >> settings.py

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
]
" > home/urls.py

# Créer home/views.py
echo "
from django.shortcuts import render

def index(request):
    return render(request, 'home/index.html')

def registration(request):
    return render(request, 'home/registration.html')
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
    <h1>Bienvenue, utilisateur connecté!</h1>
    <button id="loginBtn">Se connecter</button>
    <button onclick="window.location.href='{% url 'registration' %}'">S'inscrire</button>

    <!-- Popup de connexion -->
    <div id="loginPopup" class="popup">
        <div class="popup-content">
            <span class="close">&times;</span>
            <h2>Connexion</h2>
            <label for="username">Utilisateur:</label>
            <input type="text" id="username" name="username" required>
            <label for="password">Mot de passe:</label>
            <input type="password" id="password" name="password" required>
            <button type="submit">Se connecter</button>
        </div>
    </div>

    <script>
        // Script pour gérer le popup de connexion
        var popup = document.getElementById('loginPopup');
        var btn = document.getElementById('loginBtn');
        var span = document.getElementsByClassName('close')[0];

        btn.onclick = function() {
            popup.style.display = 'block';
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
    <form action="/inscription/" method="post">
        <!-- Nous n'allons pas traiter le POST pour l'instant -->
        <label for="username">Nom d'utilisateur:</label>
        <input type="text" id="username" name="username" required>

        <label for="email">Adresse e-mail:</label>
        <input type="email" id="email" name="email" required>

        <label for="password">Mot de passe:</label>
        <input type="password" id="password" name="password" required>

        <label for="confirm_password">Confirmer le mot de passe:</label>
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
