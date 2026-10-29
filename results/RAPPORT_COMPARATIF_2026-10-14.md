# Rapport comparatif pipeline Claude/Codex vs Sonnet seul vs Opus seul (14/10/2026)
Règle de lecture : un essai par bras, variance non mesurée. Les chiffres ci-dessous sont des mesures, pas des garanties.

## Résultats par test
| Test | Sonnet seul | Opus seul | Codex (pipeline) |
|---|---|---|---|
| Bug Project N (/5) | 3 (Claude seul) | non testé | astra high→Claude 5 (0,28 $ Claude, +30 pts jauge) ; astra medium→Claude 4 (0,35 $, +15) ; orchestration libre 4 (1,53 $) ; E3 ~3,5 (0,285 $, +13) ; allers-retours 2,5 |
| Revue 6 bugs plantés | 4/6 | non testé | sol medium 3/6 (via Claude) ; astra medium 4/6, high 5/6, xhigh 6/6 |
| T1 écriture (39 tests) | 39/39, 37 s, 0,248 $ | non testé | sol low 39/39, 38 s, 10,6 k tokens, +1 pt ; sol medium 39/39, 151 s, +2 pts, 0 $ Claude |
| T2 recherche DXF | 3/3 exacts + alerte GPL, 50 s | non testé | luna low : 3/3 exacts, 4e candidate hors PyPI (signalée non vérifiée), 47,8 k tokens, +1 pt |
| T3 revue corpus 1 (6 bugs) | non relancé (4/6 sur série précédente) | non testé | sol medium sans checklist 6/6 + 1 constat en plus, 21 k tokens, +1 pt |
| T3b revue corpus dur (8 bugs, dont 4 inter-modules) | **8/8**, 39 s, **0,27 $**, 8 tours | **8/8**, 55 s, **0,55 $**, 8 tours | relecteur sol medium **8/8** + 1 constat en plus (api.py:42, id dupliqué, non vérifié), 58 s, 18 k tokens, +1 pt ; analyste astra medium **8/8**, 0 faux, 86 s, 16,7 k tokens, +4 pts |

## Lectures
1. Sur les tests bornés (T1, T2, T3, T3b) tout le monde est au plafond : ces corpus ne départagent plus. Sonnet seul fait 8/8 à 0,27 $ ; Opus seul ne fait pas mieux pour le double du prix.
2. Là où la chaîne a gagné : le bug Project N difficile (enquête multi-fichiers, 5/5 avec astra high contre 3/5 Claude seul) et la revue du corpus 1 face à l'ancien Claude seul. Gain réel mais sur 1 essai.
3. Ce que Codex fait de mieux : décharger Claude (0 $ Claude sur T1, T2, T3, T3b) pour 1 à 4 points de jauge OpenAI. Si la jauge OpenAI est sous-utilisée, c'est du travail gratuit pour la jauge Claude.
4. Ce qui coûte : toute orchestration libre (agents Haiku/architecte après Codex) multiplie le coût Claude par 4-5. La chaîne linéaire (une passe Codex, une vérification Claude sans agent) reste la bonne forme.
5. Coût de la vérification Claude non mesuré sur T3/T3b (je n'ai pas rejoué les constats) : à faire sur le test bêta.

## Recherche web (évolutions 2026)
Sous-agents et équipes d'agents relisent chacun le contexte (équipes ~7× tokens) ; TTL du cache 1 h abonnement, 5 min avec crédits ; pause > TTL = retraitement complet. Limites Codex changées le 29/09/2026 (fenêtres par modèle) : remesurer le partage 30/70. Vérifier les plafonds sur la page officielle OpenAI.

## Recommandations
- Garder : chaîne linéaire, executant sol low pour tâches bornées contrôlées par tests, analyste astra medium par défaut, enqueteur astra high pour l'enquête difficile, jamais xhigh.
- Ne pas adopter : checklist de revue (saturé sans elle), orchestration libre.
- Claude seul (Sonnet) suffit pour revues et écriture bornées ; Codex vaut surtout quand la jauge Claude est saturée ou pour l'enquête difficile.
- Prochain test : T4 « projet bêta » avec l'auteur, en mesurant coût Claude total de la chaîne complète vs Sonnet seul.

## T4 écriture d'un module neuf (14/10, `scripts/t4/`, spec SPEC.md, grader 57 tests, ref 57/57)
Sonnet seul : 57/57, 31 s, 4 tours, **0,148 $ Claude**. `cx.sh executant` (sol low) : 57/57, 10,5 k tokens, jauge OpenAI +1 pt (12→13), **0 $ Claude**. Vérification Claude non comptée (grader automatique). Saturé comme T1 : les deux parfaits, pas de départage qualité ; le gain est le report de ~0,15 $ de Claude pour ~1 pt de jauge. Un essai par bras.

## Conclusion de la nuit
Tous les tests bornés (Project N hors saturation, T1, T3, T3b, T4) donnent la même qualité entre bras ; la différence est le coût. Codex sol low / relecteur / analyste décharge Claude pour 1 à 4 pts de jauge. Non mesuré : coût de la vérification Claude dans la chaîne sur tâche réelle, effort×modèle sur bug de concurrence (T6), lot de 10 tâches (T5).

## T4-effort : Sonnet 5.5 effort low / medium / high sur le module agenda.py (14/10, 2 essais par bras, grader 57 tests)
Sonnet : low 57/57 0,147 $ et 0,113 $ (4 tours) ; medium 57/57 0,111 $ et **0,280 $** ; high 57/57 0,140 $ et 0,159 $ (5-6 tours). Qualité identique (saturé). Le coût varie plus entre deux essais du même effort (×2,5 à medium) qu'entre efforts : avec 2 essais on ne peut pas dire que low coûte moins que medium. Tendance : high = plus de tours, pas plus cher ici.
Codex `executant` (sol low) : 57/57 ×2, 10,7 k et 9,8 k tokens, +1 pt de jauge chacun, 0 $ Claude. `relecteur` (lecture seule) ne peut pas écrire le fichier : échec attendu, non compté.
Lecture : sur une tâche bornée à spec précise, Sonnet low suffit ; l'article (coût par tâche ×15 entre max et low) dit vrai sur le principe mais notre tâche ne mesure pas l'écart. Jauge après : 16 % (5 h) / 23 % (hebdo).
