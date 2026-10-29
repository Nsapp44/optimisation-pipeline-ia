# Test gros projet (projet A, backend FastAPI) — 14/10/2026
2 tâches (analyse multifichiers + petite modif) ; juge = test pytest écrit à l'avance (9 cas : avant 6 échecs / 3 réussis).
| | A : Sonnet 5.5 medium seul | B : analyste astra medium -> executant sol low -> vérif Claude |
|---|---|---|
| Test juge | 9/9 | 9/9 |
| Suite existante (545 tests) | 538 ok, 7 échecs identiques | 538 ok, 7 échecs identiques (origines WebSocket, non vérifiés sur l'original) |
| Coût Claude | 0,47 $ (31 tours, 884 k cache reads) | ~0 $ hors ma vérification (diff + tests, quelques k tokens) |
| Jauge OpenAI | 0 | 5 h : +10 pts, hebdo +1 |
| Temps | 133 s | 163 s (126 analyse + 27 exécution) |
| Analyse | correcte, avoue ne pas avoir lancé 4 scénarios | correcte, avec tableau des 2 divergences et plan exact |
Diff : tailles équivalentes (B : 44 lignes touchées, A : 56). Qualité égale ; B plus propre (isinstance LifecycleEvent). Sur ce gros projet la chaîne Codex économise ~0,47 $ Claude pour ~10 pts de jauge 5 h ; qualité identique (tâches bornées, saturé).
