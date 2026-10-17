# Test grandeur nature — Bureau entreprise (backend), 16/10/2026
Base : copie de app/backend, baseline 7 échecs préexistants / 538 réussis. Prompt : gn/PROMPT.txt.
## Tour 1 — ENH-006 (limiteur par session + batch), difficulté moyenne
| Bras | $ Claude | Tours | Durée | OpenAI 5h | Suite complète | Remarque |
|---|---|---|---|---|---|---|
| A Sonnet seul | 0,64 | 22 | 168 s | 0 (+1 = sonde) | 8 éch. (7 + 1 imposé par le plan) / 559 ok, 22 tests ajoutés | propre |
| B Codex executant (sans Claude) | 0 | - | 118 s | +1 (net de la sonde) | 29 éch. / 520 ok | ses nouveaux tests polluent la base partagée (sans eux : 8 éch.) ; Codex n'a pas pu lancer la suite (bash pt.sh planté dans son bac à sable) |
| D Sonnet + agents | 0,89 | 8 | 206 s | 0 | 8 éch. / 555 ok | propre |
Lecture : A = D en qualité, D 1,4× plus cher ; B pas cher mais défaut réel non vu faute de pouvoir lancer la suite.

## Tour 1 — bras E1 (Codex puis vérification Claude), ENH-006
E1 : 0,41 $ Claude (21 tours, 207 s) + ~1 pt OpenAI → 8 échecs / 541 réussis. Claude a corrigé la pollution de tests laissée par Codex (B : 29 échecs). Contre A : 0,64 $, 8 échecs / 559 réussis.

## Tour 2 — ENH-004 (tâche difficile : éviction LRU, rétention, replay paginé)
Baseline : 7 échecs préexistants. Les 7 tests `TestReplayPagination` existants contredisent le plan (liste JSON vs `{total,offset,limit,entries}`, plafond 2000 vs 1000) : un bras qui les laisse rouges est conforme au plan, pas fautif.

| Bras | $ Claude | Durée | Suite | Remarque |
|---|---|---|---|---|
| A4 Sonnet seul | 2,01 $ (94 tours) | 539 s | 19 échecs / 555 | 7 connus + 12 contredits (replay ×6, éviction ×3, rétention ×3), laissés rouges, sans pollution |
| D4 Sonnet + agents | ~2,89 $ (JSON final perdu : limite de session) | – | 8 échecs / 563 | a adapté les tests contredits ; 1 échec en plus (`test_eviction_is_transparent_to_state`) |
| B4 Codex seul | 0 $ | – | 14 échecs / 534 | 7 connus + replay ×7 (contredits) ; +4 pts OpenAI ; bac à sable : pas de `bash pt.sh` |
| E4 Codex (prompt amélioré) | 0 $ | – | 7 échecs / 538 | Codex n'a RIEN écrit (contrat « à trancher ») → invalide ; +1 pt OpenAI |
| E4c = B4 + vérif Claude | 0,23 $ (16 tours, 74 s) | 74 s | 14 échecs / 534 | Claude : « rien d'important de cassé », aucune correction |

Incidents : limite de session Claude atteinte (D4/E4 en api_error, reprise 14 h) ; E4b mal copié (0,14 $ perdus).

## Lecture (provisoire)
- Tâche moyenne : Sonnet seul ≈ Codex + vérif en qualité ; Codex seul pollue la suite. La vérif Claude répare.
- Tâche difficile : la passe Codex (B4) est correcte sur le code (même 7 échecs contredits que A4 côté replay) pour 0 $ Claude + 4 pts OpenAI ; la vérif Claude coûte 0,23 $ contre 2,01 $ pour A4 (≈ 9× moins). Mais un run (E4) sur deux, Codex ne livre rien : fiabilité à confirmer.
- Biais : un seul run par bras ; /usage de Nolann bruité ; D4 non vérifié après coupure.
- ×3 : plausible seulement avec Codex en première passe + vérif courte Claude ; non prouvé (n = 1).

## Tour 3 (ENH-004, 16/10) — E6, D7, F6, G6
Note : pt.sh manquait dans D6/E6/F6/G6 pendant le tour (D6 invalide, arrêté sans rien écrire) ; D refait en D7 avec pt.sh.
| Bras | $ Claude | Tours | Tests (échecs / réussis) |
|---|---|---|---|
| E6 Codex + vérif Claude | 0,22 | 19 | 20 / 527 |
| D7 Sonnet + agents | 2,57 | 3 (agents) | 14 / 560 |
| F6 Opus seul | 4,04 | 100 | 21 / 548 |
| G6 Opus + agents | 3,44 | 24 | 9 / 559 |
Références tour 2 : A4 2,01 $ (19 / 555), D4 ~2,89 $ (8 / 563). n = 1 par bras ; diffs non relues ; jauges OpenAI non lues.

### E8 (17/10) : Codex adapte les tests contredits + vérif Claude adapte aussi
0,53 $ Claude (22 tours, 101 s) ; 7 échecs (= seuil de base) / 545 réussis ; OpenAI +8 pts (5 h) / +1 (hebdo). Moins de tests ajoutés que D7/G6 (553 vs 574 au total). Diffs non relues. n = 1.
Lecture : le « 20 échecs » de E6 venait de la consigne « laisse rouges » (même convention que A4 : 19). Chaîne Codex + vérif = qualité de A/D pour 0,2-0,5 $ au lieu de 2-3 $.

### Relecture de la diff E8 (lecteur Sonnet, lecture seule, rien exécuté)
- Plan : toutes les exigences de code faites (réglages, index, éviction LRU/TTL, SessionJanitor, ReplayPage paginé, câblage main.py).
- Aucun bug HIGH/CRITICAL (>80 %). Mineurs : session sans ligne en base jamais évincée par le TTL ; `total` du replay compte les EventRecord bruts.
- Tests existants adaptés au nouveau contrat, sans affaiblissement réel ; un test passe de « limit=99999 → 200 » à « → 422 » (voulu par `le=1000`).
- Écart non demandé : ancien réglage SESSION_IDLE_EVICT_SECONDS (6 h) remplacé par SESSION_IDLE_TTL_SECONDS (1 h), éviction limitée aux sessions « completed ».
- Tests demandés par le plan et ABSENTS : restauration transparente après éviction (égalité d'état), course éviction/événement, `_touch` aux 3 endroits, taille de page du replay, EXPLAIN QUERY PLAN, start/stop du janitor. → explique 545 vs 560 tests : E8 est moins complet en couverture que D7/G6.

## Retest E9 (17/10) : reproductibilité de E8
Même recette que E8 (Codex executant adapte les tests contredits + une vérification Claude Sonnet sans agents) : 0,33 $ Claude (16 tours, 82 s), **7 échecs / 543 réussis** (= seuil de base, mêmes 7 échecs préexistants). OpenAI : +13 pts sur 5 h, +2 hebdo. E8 (0,53 $, 7 / 545) puis E9 (0,33 $, 7 / 543) : résultat reproduit sur 2 essais (n = 2).
