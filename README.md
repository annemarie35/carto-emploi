# ANGO

Projet de cartographie des emplois du numérique en France :  http://ango.simplon.co/index.html.com/


# pré-requis

- ruby '2.1.3' avec rbenv ou un autre gestionnaire de versions
- postgresql http://www.postgresql.org/
`sudo apt-get install postgresql`
`sudo apt-get install postgresql-client-9.3`
`sudo apt-get install postgresql postgresql-contrib`

- bundler http://bundler.io/
`gem install bundler`


# récupérer le projet

`git clone https://github.com/simplonco/carto-emploi.git`

Puis lancer l'installation des gem :

`bundle install`

# configurer la base de données


Modifier le fichier `congig/database.yml` avec vos propres données.


# configurer les variables d'environnement

renommer les fichiers .envsample et /parser/.envsample en .env et remplacer les valeurs si nécessaire
Ex :

```
DATABASE_PASSWORD=pole_emploi
DATABASE_USER_NAME="pole_emploi"
DATABASE_URL=postgres://..... #valeur donnée par heroku ou autre
RACK_ENV=development
```

puis modifier le ficher '/config/database.yml' si besoin est

# configuration de la base de données

lancer le terminal de postgres
`sudo su postgres`
puis
`psql`

ou `sudo -u postgres psql`
puis

`create role pole_emploi with createdb login password 'pole_emploi';`

Pour vérifier que le changement est OK et voir la liste des utilisateurs  :

`\dgh`

* utile :
Pour voir l’aide de Postgres :
`\?`
Pour sortir de la console PSQL et revenir à la ligne de commande du terminal Ctrl D (deux fois !).


# créer les tables en local (partie à modifier après tests)

## Via active record
Pb : les données de database.yml ne sont pas prises en compte car la base n'a pas l'utilisateur pole_emploi comme owner :

`rake dotenv`


`rake db:create RACK_ENV='development'`

(essayer bundle exec rake db:create RACK_ENV='development')

puis `rake db:structure:load` qui va charger la structure de la bdd

ou `rake ango:create_tables` un script sql qui prend en compte l'environnement.

## Via un script maison

Lancer la tâche `rake ango:create_tables`
Ce script crée les tables dans la base pole_emploi avec comme owner pole_emploi.
Penser à modifier le fichier `database.yml` si vous souhaitez modifier les paramètres.

## créer les tables sur heroku

Dans le terminal :

`heroku pg:psql -a ango-jobs <db/structure.sql`


( heroku pg:psql -a your-app-name <db/structure.sql )



# :::::::::  Lancer le parser ::::::::::::::::

Voir la liste des tâches disponibles ` rake -T`

### 1. Récupération des urls

Lancer le premier script qui récupère les urls et id correspondant aux offres d'emplois pour les jobs du numérique

Attention : le script génère de nombreuses url !
Sachant que les départements vont de 1 à 95 et que le 20 n'existe pas, c'est la Corse et est remplacé par 2A et 2B
`rake parser:url_parse_1_19`   # insère les urls des offres des départements 1 à 19
`rake parser:url_parse_21_95`  # insère les urls des offres des départements 21 à 95
`rake parser:url_parse_2A_2B`  # insère les urls des offres disponibles en Corse

ou

`rake ango:a_l_abordage` # insère les urls des offres de tous les départements


# ::::::: Pour faire la même chose en production :::::::::::::::::::::

Depuis votre terminal, ajouter `heroku run` avant la listes des tâches rake mentionnées au paragraphe précédant.
Exemple :  `heroku run rake -T`

### 2. Nettoyage de la base d'url : (ATTENTION PARTIE A METTRE A JOUR PASSER AU NUMERO 3)

Une fois que l'on a rempli la base avec les urls, il faut nettoyer cette base.
On dispose de 2 tâches rake.


`rake clean_db:delete_urls_from_parse`

On enlève les offres que l'on ne veut pas faire apparaître sur la carte et donc qu'on ne veut pas enregistrer dans la base de données.
C'est un script un peu long qui nécessite l'analyse du contenu des offres (supprime les codes romes et adresses invalides ainsi que les offres non disponibles de la base de données d'url).

Ce script enlève de la bdd les url dont :
- supprime les urls (parse) qui ont déja été ajoutées dans la base des offres (job_offers)
- code rome invalides
- adresses invalides (Ex Ile-de-France, on ne garde que les villes)
- offre indisponible sur le site de pôle emploi

Alternative, sur Heroku on peut executer des script sql : `heroku pg:psql -a ango-jobs <db/delete_from_parse.sql`

- Enfin, il arrive que les offres ne soient plus disponibles passées un certains temps (l'offre a été pourvue par exemple), on peut enlever ces offres de la base de données job_offers :



`rake clean_db:delete_offers`




### 3. Insertion des données des offres d'emplois

Une fois que la base d'url est propre on peut passer à l'étape suivant, l'insertion des données des offres d'emploi (titre du métier, code rome, etc.)

`rake ango:insert_offers`    # parse les urls et insère le détail des offres dans la base de données

Attention, c'est long quand la base est vide !!



### 4. Nettoyage de la base de données

Ces opérations de maintenance sont effectuées tous les jours afin de garantier une base d'offres pertinentes. Voir étape 2.

# Lancer l'api sur un serveur

Dans le terminal :

`shotgun`

# Accès à la partie Admin

`\admin`
Les logins et mots de passe sont à modifier dans le fichier .env (voir le modèle .envsample)

Il faut également renseigner la variable SESSION_SECRET avec un mot de passe


Ex d'urls pour visualiser le fichier json généré :

- Voir toutes les offres d'emplois disponibles : http://0.0.0.0:9393/emploi?limit=50&p=2
- Chercher un métier parmi les offres : http://0.0.0.0:9393/search/administrateur?limit=3&p=2
- Chercher un métier situé à une certaine distance : http://0.0.0.0:9393/geosearch/48.86833,2.66833?text=administrateur&d=50&limit=5&p=1


# Documentation utile

- Gem Geokit pour la géolocalisation d'une adresse : http://www.rubydoc.info/gems/geokit/1.9.0


# Tester la partie parser

Les pages de détail d'offres disponibles pole emploi étant mouvantes, j'ai créé des copies mais il faudrait les mettre à jour

- se mettre à la racine du site et lancer un serveur `ruby -run -e httpd . -p 8000`
- lancer les tests `ruby body_parser_test.rb `