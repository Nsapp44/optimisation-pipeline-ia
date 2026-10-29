# Codex comme exécutant / relecteur (pipeline 30 % Claude / 70 % Codex) — décidé 11/10/2026, changé le 11/10 au soir (Claude à 84 % de sa jauge)

À lire quand on confie du code, de la lecture, une recherche ou une revue à Codex (pas pour le dialogue image/CAO : voir SKILL.md).
Source de vérité des mesures : `<PROJECT_DIR>/SUIVI.md`, `docs\mesures.md`. Détail ancien : `docs\codex_a_reinjecter.md`.

## Principes
- **Décision l'auteur 16/10 (bancs T8/T9, 2 runs)** : par défaut Sonnet seul (meilleur rapport qualité/jauge). Codex seulement pour
  (a) analyse difficile (Project N 4,17 contre 3,0) et (b) code borné contrôlé par un correcteur automatique : dans ces cas PAS de
  « vérif Claude » derrière (le correcteur tranche), c'est ce qui rend la chaîne chère en jauge (+10 pts). Sans OpenAI (compte
  du travail) : Sonnet seul ; `architecte` seulement aux déclencheurs (test rouge après 2 corrections, contradiction, bug profond).
  Plan de l'architecte : uniquement des commandes que la session peut lancer (pytest), avec plan de repli ; si une commande est
  refusée, Sonnet s'adapte au lieu de s'arrêter (h5 bras C = 0/5 deux fois pour ça).
- **Mesure grandeur nature 17/10 (ENH-004, n = 1, voir `docs/mesures_grandeur_nature_2026-10-16.md`)** : chaîne « Codex implémente
  (`executant`) puis UNE vérification Claude Sonnet sans agents » = 0,53 $ Claude, 7 échecs (= seuil de base), contre 2-3,4 $ pour
  Sonnet seul / + agents / Opus. Condition mesurée : la consigne dit à Codex (et à la vérification) d'**ADAPTER au nouveau contrat
  les tests existants que le plan contredit, sans les affaiblir, et de les lister** (avec « laisse-les rouges » : 20 échecs, même
  score que Sonnet seul). Consigne à Codex : commande pytest directe avec le python du venv (pas `bash pt.sh`, plante dans son bac à
  sable) ; « une réponse sans fichier modifié = échec » (sans cette phrase, 1 essai sur 2 n'écrivait rien). Codex seul sans
  vérification : non fiable (pollution d'état, rien d'écrit).
- **Un « plus », jamais une dépendance** : avant chaque étape Codex, tester (commande présente, connecté, quota). Sinon on saute
  l'étape et le pipeline Claude seul (lecteur, chercheur, executant, architecte) suffit.
- **Partage visé 30 % Claude / 70 % Codex (12/10 : OpenAI sous-utilisé, Claude surchargé ; équilibrer si l écart dépasse 15 points)**, images comptées à part (budget séparé, peu d'itérations, test de coût avant une série).
- **Chaîne de vérification (sans nouvel agent, un agent coûte 30-95 k au démarrage)** : 1) rapport de preuves de Codex ; 2) `testeur` lance les tests ; 3) zone fragile ou rapport vague → `chasseur-erreurs` (ou `securite-web`) sur les fichiers modifiés ; 4) Claude relit la diff ; sûr à plus de 80 % = validé, sinon Claude corrige seul (voir chaîne linéaire).
- **Claude orchestre et juge « en diagonale »** : rapport de preuves de Codex, diff survolé, un test ou une capture ciblés. Relecture
  plus poussée si le rapport est vague, si la zone est fragile (interface, données, sécurité) ou si un oubli est déjà arrivé.
- **Jamais accepter le code de Codex tel quel** (rendu mal intégré, 11/10). Le brief exige : relire les fichiers voisins et conventions,
  lancer code et tests, vérifier l'intégration, et rendre en tête « commandes lancées / non lancées » (en read-only ou sandbox
  Windows cassée « setup refresh had errors » il peut ne rien lancer : tout revérifier).
- **CHAÎNE LINÉAIRE (décidée et mesurée le 12/10, remplace les allers-retours qui « rendent fous » les deux)** : Codex fait UNE
  passe (analyse, relecture ou code), puis Claude vérifie/complète UNE fois, sans renvoi. Claude relit les lignes citées, ne
  rejette un constat qu'en le démontrant faux (pas sur un coup d'œil : D2 a perdu un point ainsi), liste ce qu'il n'a pas relu.
  Mesures Project N : Claude seul 3/5 ; allers-retours 2,5/5 ; chaîne astra medium 4/5 (+15 pts jauge 5 h) ; astra high 5/5 (+30 pts).
- **Vérification après Codex (mesuré E2 : 1,53 $ au lieu de ~0,3 $)** : Claude vérifie lui-même, en lisant les lignes citées. Pas de
  `lecteur` ni d'`architecte` ensuite, sauf contradiction entre constats ou test échoué. Avant de rejeter un constat de timeout,
  vérifier l'option réellement activée (timeout configuré ≠ appliqué : ex. `throwOnRequestTimeout` absent dans `s3.ts:12`).
- **Analyse / enquête / audit de code** : `cx.sh analyste` (astra medium) par défaut ; `cx.sh enqueteur` (astra high) pour
  l'enquête difficile ou à enjeu. **xhigh : jamais** (décision l'auteur 12/10, 2× le coût pour ~1 bug de plus). Pas de Codex `lecteur` pour
  un gros audit de lecture : Claude direct (agent à partir de ~3 fichiers).
- **Écriture de code** : `executant` sol low écrit (tâches bornées contrôlées par tests ; low = medium sur 5 exercices du 13/10, non validé en général) ; `relecteur`/astra relit ; Claude vérifie une fois.
- **Pas satisfait** : Claude ne renvoie pas à Codex en boucle. Il corrige seul ; si bloqué → `architecte` Claude (Opus) ; sur le
  compte avec advisor → advisor d'abord. Un renvoi à Codex seulement exceptionnel (un seul).

## Rôles = nos agents : `<PROJECT_DIR>/codex/cx.sh <rôle> "<consigne>" [dossier]`
| Rôle | Réglage |
|---|---|
| lecteur | gpt-6-luna low, read-only |
| chercheur | luna low + `--search` |
| executant | gpt-6.1-sol low, workspace-write |
| relecteur | sol medium, read-only |
| architecte | astra high (avis dur, avec parcimonie : quota) |
| analyste | astra medium read-only (enquête courante) |
| enqueteur | astra high read-only (enquête difficile ; plafond, jamais xhigh) |
Table provisoire (séries 4-6). Discipline de Codex : `AGENTS.md` à la racine du dépôt (copié dans le projet ou dans `~/.codex/AGENTS.md`).
### Variables de `cx.sh` (toutes optionnelles)
- `CX_AGENTS_DIR` (défaut `$HOME/.claude/agents`), `CX_LOG` (défaut `$HOME/.cx_tokens.log`), `CX_NODE_DIR`, `CX_WIN_SANDBOX` (`none` hors Windows), `CX_M_<RÔLE>` (modèle d'un rôle).
- `CX_BIN` : exécutable appelé à la place de `codex` (défaut `codex` ; sert aux tests factices).
- `CX_MAX_PARALLEL` : nombre maximal de processus Codex simultanés, tous appels `cx.sh` confondus (défaut 3). Sémaphore par verrous `mkdir` `slot1..slotN`.
- `CX_LOCK_DIR` : dossier des verrous (défaut `${TMPDIR:-/tmp}/cx-locks`). Un verrou dont le pid (écrit dans le slot) est mort est nettoyé.
- `CX_LOCK_WAIT` : attente maximale d'un slot libre, en secondes (défaut 600) ; au-delà, erreur claire et code de sortie 3.
Échelle d'un bug qui résiste : Sonnet medium (2 essais) → Codex astra high read-only (si dispo) → `architecte` Claude. Pas d'agent `debug`.

## Usage technique
- 1 tâche = 1 session `codex exec`, `-m` explicite (défaut config = astra medium). `resume` seulement pour corriger la même tâche.
  Session longue → nouvelle session + court .md (consigne, état, défauts). Un livrable par session. Sous-agents Codex : désactivés.
- Une seule chaîne de tests à la fois. Commande (Git Bash) :
  `codex exec --skip-git-repo-check -s workspace-write -c 'windows.sandbox="unelevated"' --json "<prompt>" < /dev/null`
  (`codex.cmd`, Node dans le dossier Node.js (sous Windows)). Jamais d'identifiants.

## Tâches visuelles
Codex en read-only écrit du code visuel sans le voir. Le brief donne : dimensions exactes, zone utile, polices, marges, palette
(fixer fond ET texte, pas de carte dans une carte), noms exacts des états/props existants, états transitoires à tester, « rendre le
fichier complet ». Boucle : Codex écrit → Claude applique + capture → défauts renvoyés à Codex. Tâche bornée (1 fichier) ≈ 4 min.
Normaliser les CRLF en fin. Images : skill `image-prompts`, validation de l'auteur avant de figer.

## Quota (OpenAI Plus)
- Fenêtres 5 h et hebdo partagées entre CLI, appli, Work, agents (le chat normal est à part). L'auteur utilise Codex aussi : mesurer en relatif.
- **Sonde fraîche** (`codex exec` d'une ligne) avant de lire une jauge (une sonde périmée a donné 99 % à tort). Budget +25 points
  depuis la jauge fraîche ; +10 à +12 pour un simple test. Équilibrer Claude/Codex si écart > 15 points.
- **Calibrage** : en fin de session « hard », viser ~10 % restant côté OpenAI (ni 0 %, ni 50 %).
- L'appli montre le % RESTANT, nos scripts le % UTILISÉ : toujours convertir pour l'auteur.
- Plus de quota : pipeline Claude habituel, images mises en pause (SUIVI.md : prompt, schéma, état) jusqu'au retour du quota.
