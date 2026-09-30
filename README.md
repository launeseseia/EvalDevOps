# EvalDevOps

[![CI](https://github.com/launeseseia/evaldevops/actions/workflows/ci.yml/badge.svg)](https://github.com/launeseseia/evaldevops/actions/workflows/ci.yml)
[![CD](https://github.com/launeseseia/evaldevops/actions/workflows/cd.yml/badge.svg)](https://github.com/launeseseia/evaldevops/actions/workflows/cd.yml)

Application Flask conteneurisée.

Suite à un `git push` : lint → tests de l'app → déploiement → push du package dans ghcr → observabilité.

## Démarrer la stack

```bash
git clone https://github.com/launeseseia/evaldevops.git
cd evaldevops
docker compose up -d --build
docker compose ps
```

La sortie de `docker compose ps` doit montrer les conteneurs en `healthy`.

## Endpoints déployés

- `/health` : vérifie la santé de l'app, renvoie un 200 si OK et un 503 si Redis est KO
- `/status` : donne le nom du service et le SHA du commit
- `/visits` : compteur de visites, la valeur est stockée dans Redis
- `/metrics` : endpoint scrapé par Prometheus
- `/simulate-error` : renvoie une erreur
- `/simulate-latency` : répond avec une latence élevée

## Intégration continue (CI)

Déclencheurs : chaque `push` sur `main` et chaque `pull_request` vers `main`.

- **Lint** : vérification syntaxique du Python
- **Yamllint** : vérification syntaxique des fichiers `.yml`
- **Test** : lancement des tests sur `app.py`
- **Build** : construction de l'image Docker
- **Ci-ok** : échoue si un job précédent est KO, sinon valide le passage au CD

## Déploiement continu (CD)

Déclencheur : job `Ci-ok`.

### Rollback manuel

Si un problème apparaît après un déploiement réussi, on peut faire un rollback à l'aide des commandes suivantes :

```bash
git revert <sha-du-commit>
git push origin main
```

### Lancer le runner self-hosted

Le déploiement s'exécute sur la machine locale :

```bash
cd ~/actions-runner
./run.sh
```

## Observabilité

Métriques exposées sur `/metrics` :

- `http_requests_total` : nombre de requêtes reçues
- `http_request_duration_seconds` : latence, permet de calculer p95 / p99
- `app_build_info` : version et commit déployés

Prometheus scrape `/metrics` toutes les 5 secondes.
