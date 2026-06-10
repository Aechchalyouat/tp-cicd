# CI/CD Demo — Nginx + GitHub Actions

Projet réalisé dans le cadre du TP CI/CD (EPSI). Pipeline complet Niveau 1 → 3.

## Structure du projet

```
.
├── .github/
│   └── workflows/
│       └── ci.yml          # Pipeline GitHub Actions (N1 + N2 + N3)
├── nginx/
│   └── nginx.conf          # Config Nginx avec endpoint /health
├── Dockerfile              # Image Nginx Alpine
├── index.html              # Page web de démonstration
└── README.md
```

## Schéma du Pipeline

```
┌──────────┐    push/PR    ┌─────────────────────────────────────────┐
│  Dev     │ ────────────► │  JOB 1 : build-and-test                 │
│  (code)  │               │                                         │
└──────────┘               │  1. Checkout                            │
                           │  2. Vérification fichiers               │
                           │  3. docker build                        │
                           │  4. nginx -t (test config)              │
                           │  5. docker run                          │
                           │  6. curl / → HTTP 200                   │
                           │  7. curl /health → HTTP 200             │
                           └────────────────┬────────────────────────┘
                                            │ si push main
                                            ▼
                           ┌─────────────────────────────────────────┐
                           │  JOB 2 : publish                        │
                           │                                         │
                           │  - Login GHCR (GITHUB_TOKEN)            │
                           │  - docker build + push                  │
                           │  - Tag : sha-<commit_sha>               │
                           │  - Tag : latest                         │
                           └────────────────┬────────────────────────┘
                                            │
                                            ▼
                           ┌─────────────────────────────────────────┐
                           │  JOB 3 : deploy-production              │
                           │                                         │
                           │  ⚠️  Validation manuelle requise        │
                           │  (Environment "production" sur GitHub)  │
                           │                                         │
                           │  → Déploiement en production            │
                           └─────────────────────────────────────────┘
```

## Niveaux implémentés

| Niveau | Fonctionnalité | Status |
|--------|---------------|--------|
| **Niveau 1** | Vérification fichiers, `nginx -t`, pipeline manuel | ✅ |
| **Niveau 2** | Trigger push/PR, test HTTP `/` et `/health`, 0 secret dans les logs | ✅ |
| **Niveau 3** | Push image GHCR, tag SHA, validation manuelle prod | ✅ |

## Sécurité

- **Aucun secret dans le code** — `GITHUB_TOKEN` est injecté automatiquement par GitHub Actions
- Le token n'est jamais loggué ni visible dans les artifacts
- Principe du moindre privilège : permission `packages: write` uniquement sur le job publish

## Configuration requise pour le Niveau 3

1. Aller dans **Settings > Environments** du repo GitHub
2. Créer un environment nommé `production`
3. Activer **Required reviewers** et ajouter votre compte
4. Chaque déploiement en prod demandera une approbation manuelle

## Tester localement

```bash
# Build
docker build -t nginx-ci-demo .

# Run
docker run -d --name test -p 8080:80 nginx-ci-demo

# Tests
curl http://localhost:8080/          # doit retourner HTTP 200
curl http://localhost:8080/health    # doit retourner "OK"

# Test nginx -t
docker run --rm nginx-ci-demo nginx -t

# Cleanup
docker rm -f test
```

## Casser volontairement le pipeline (Niveau 1)

Pour vérifier que le pipeline détecte bien les erreurs, modifier `nginx/nginx.conf` :

```nginx
# Ajouter une directive invalide
invalid_directive;
```

Le job **build-and-test** échouera à l'étape `nginx -t` avec une erreur rouge. ✅
