# 🍽️ Application Serveur Restaurant - Foodly

## 📱 Vue d'ensemble

Application mobile Flutter professionnelle destinée **UNIQUEMENT aux SERVEURS** de restaurant. Cette application permet aux serveurs de gérer efficacement les tables, prendre les commandes et suivre leur statut en temps réel.

## ✨ Fonctionnalités Principales

### 🔐 Authentification
- Connexion sécurisée pour les serveurs
- Sauvegarde automatique des informations du serveur
- Gestion de session avec middleware d'authentification

### 🪑 Gestion des Tables
- **Écran**: `TablesScreen`
- **Contrôleur**: `TableController`
- Vue en grille de toutes les tables du restaurant
- Filtrage par statut (Disponible, Occupée, Réservée)
- Recherche de tables
- Indicateurs visuels de disponibilité
- Sélection de table pour prise de commande

### 📋 Menu et Prise de Commande
- **Écran**: `MenuScreen`
- **Contrôleur**: `MenuController`
- Affichage du menu par catégories (Entrées, Plats, Boissons, Desserts)
- Images des plats avec cache réseau
- Recherche de plats
- Ajout au panier avec quantités
- Commentaires personnalisés (ex: sans piment)
- Panier dynamique avec calcul automatique du total

### ✅ Validation de Commande
- **Écran**: `CartValidationScreen`
- Récapitulatif complet de la commande
- Informations table et serveur
- Notes pour la cuisine
- Confirmation avant envoi

### 📦 Suivi des Commandes
- **Écran**: `OrdersScreen`
- **Contrôleur**: `OrderController`
- Filtrage par statut:
  - En attente (⏰)
  - En préparation (👨‍🍳)
  - Prête (✅)
  - Livrée (📦)
- Notifications push quand commande prête
- Validation de livraison par le serveur
- Historique des commandes

### 🔔 Notifications Temps Réel
- **Service**: `NotificationService`
- **WebSocket**: `WebSocketService`
- Notifications locales quand commande prête
- Connexion WebSocket avec reconnexion automatique
- Mise à jour en temps réel du statut des commandes

## 🏗️ Architecture

### Modèles de Données
```
lib/models/
├── table_model.dart          # Modèle de table
├── menu_item_model.dart      # Modèle de plat/boisson
├── order_item_model.dart     # Modèle d'article de commande
└── order_model.dart          # Modèle de commande complète
```

### Contrôleurs
```
lib/controller/apps/server/
├── table_controller.dart     # Gestion des tables
├── menu_controller.dart      # Gestion du menu et panier
└── order_controller.dart     # Gestion des commandes
```

### Vues
```
lib/views/apps/server/
├── server_home_screen.dart       # Écran principal avec navigation
├── tables_screen.dart            # Liste des tables
├── menu_screen.dart              # Menu et panier
├── cart_validation_screen.dart   # Validation commande
└── orders_screen.dart            # Suivi des commandes
```

### Services
```
lib/helpers/services/
├── notification_service.dart     # Notifications locales
└── websocket_service.dart        # Communication temps réel
```

## 🎨 Interface Utilisateur

### Design System
- **Responsive**: Utilisation de `flutter_screenutil` et module `MyResponsive`
- **Thème**: Intégration avec le thème existant de l'app
- **Icônes**: Lucide Icons pour une interface moderne
- **Couleurs**: Palette cohérente avec indicateurs de statut

### Navigation
- **BottomNavigationBar** avec 3 onglets:
  1. 🍽️ Tables
  2. 📋 Commandes
  3. 👤 Profil

### Animations
- Transitions fluides entre écrans
- Animations de sélection dans la navigation
- Feedback visuel sur les interactions

## 🔧 Configuration Technique

### Dépendances Utilisées
```yaml
dependencies:
  flutter_screenutil: ^5.9.3        # Responsive design
  get: ^4.6.5                        # State management & routing
  cached_network_image: ^3.3.1      # Cache d'images
  lucide_icons: ^0.257.0             # Icônes modernes
  stomp_dart_client: ^2.0.0          # WebSocket
  flutter_local_notifications: ^17.2.2  # Notifications
  dio: ^5.5.0+1                      # HTTP client
  intl:                              # Formatage dates
```

### Routes Configurées
```dart
/server-home          # Écran principal serveur
/tables               # Liste des tables
/menu                 # Menu et prise de commande
/orders               # Suivi des commandes
/cart-validation      # Validation de commande
```

### Middleware d'Authentification
Toutes les routes serveur sont protégées par `AuthMiddleware` qui vérifie:
- Token d'authentification valide
- Session active
- Redirection vers login si non authentifié

## 🚀 Utilisation

### Flux de Travail Serveur

1. **Connexion**
   - Le serveur s'authentifie avec ses identifiants
   - Redirection automatique vers `/server-home`

2. **Sélection de Table**
   - Navigation vers l'onglet "Tables"
   - Recherche/filtrage de la table souhaitée
   - Sélection de la table disponible

3. **Prise de Commande**
   - Affichage automatique du menu
   - Parcours des catégories
   - Ajout des plats au panier avec quantités et commentaires
   - Visualisation du panier en temps réel

4. **Validation**
   - Vérification du récapitulatif
   - Ajout de notes pour la cuisine (optionnel)
   - Confirmation de la commande

5. **Suivi**
   - Navigation vers l'onglet "Commandes"
   - Filtrage par statut
   - Réception de notification quand prête
   - Validation de la livraison au client

## 📊 Gestion des États

### Statuts de Table
- `available` - Disponible
- `occupied` - Occupée
- `reserved` - Réservée

### Statuts de Commande
- `pending` - En attente
- `in_preparation` - En préparation
- `ready` - Prête
- `delivered` - Livrée
- `cancelled` - Annulée

## 🔐 Sécurité

- Authentification JWT
- Tokens stockés de manière sécurisée avec `SharedPreferences`
- Middleware de protection des routes
- WebSocket sécurisé avec authentification

## 📱 Responsive Design

L'application utilise le module de responsivité existant:
- `MyResponsive` pour l'adaptation automatique
- `MyScreenMediaType` pour la détection du type d'écran
- `flutter_screenutil` pour les dimensions adaptatives

### Breakpoints
- `xs` (< 576px) - Mobile
- `sm` (< 768px) - Tablet
- `md` (< 1200px) - Laptop
- `lg` (< 1400px) - Desktop
- `xl` (< 1800px) - Large Desktop
- `xxl` (> 1800px) - Extra Large Desktop

## 🎯 Points Importants

### ⚠️ Aucune Fonctionnalité Admin
Cette application est **exclusivement** pour les serveurs. Aucune fonction d'administration n'est intégrée:
- Pas de gestion du menu
- Pas de gestion des tables
- Pas de gestion du personnel
- Pas de statistiques/rapports

### 🔄 Temps Réel
- WebSocket connecté automatiquement après login
- Reconnexion automatique en cas de déconnexion
- Mise à jour instantanée des statuts de commandes
- Notifications push pour les commandes prêtes

### 💾 Persistance
- Informations serveur sauvegardées localement
- Table sélectionnée mémorisée
- Token d'authentification persistant
- Option "Se souvenir de moi"

## 🐛 Gestion des Erreurs

- Messages d'erreur clairs et en français
- Snackbars pour les feedbacks utilisateur
- Logs détaillés pour le débogage
- Gestion des erreurs réseau avec retry

## 🔮 Évolutions Futures Possibles

- Mode hors ligne avec synchronisation
- Scan QR code pour les tables
- Statistiques personnelles du serveur
- Chat avec la cuisine
- Gestion des pourboires
- Multi-restaurant pour serveurs itinérants

## 📝 Notes de Développement

### API Endpoints Attendus
```
GET  /api/tables                    # Liste des tables
GET  /api/menu-items                # Liste des plats
POST /api/orders                    # Créer une commande
GET  /api/orders?serverId={id}      # Commandes du serveur
PATCH /api/orders/{id}              # Mettre à jour une commande
```

### WebSocket Topics
```
/topic/orders/{serverId}            # Mises à jour pour un serveur
/user/queue/orders                  # Messages personnels
```

## 🎓 Technologies & Patterns

- **Architecture**: MVC avec GetX
- **State Management**: GetX Controllers
- **Routing**: GetX Navigation
- **DI**: GetX Dependency Injection
- **Storage**: SharedPreferences
- **HTTP**: Dio
- **WebSocket**: STOMP over SockJS
- **Notifications**: Flutter Local Notifications
- **Images**: Cached Network Image
- **Responsive**: ScreenUtil + Custom Module

---

**Version**: 1.0.0  
**Plateforme**: iOS & Android  
**Framework**: Flutter 3.6.1+  
**Langue**: Français
