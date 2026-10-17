# Mesures bug Project N (12/10/2026)

| Bras | Chaîne | Note /5 | Coût Claude | Jauge OpenAI 5 h |
|---|---|---|---|---|
| A | Claude seul | ~3 | 0,31-0,40 $ | 0 |
| C | allers-retours | ~2,5 | 0,37 $ | +11 |
| D1 | astra high → Claude (scripté) | 5 | 0,276 $ | +30 |
| D2 | astra medium → Claude (scripté) | 4 | 0,347 $ | +15 |
| E1 | pipeline à jour, Codex bloqué (redirection) | ~3 (invalide) | 0,893 $ | 0 |
| E2 | pipeline à jour, orchestration libre (analyste 45,5 k tokens + 2 Haiku + architecte) | 4 | 1,532 $ | +8 |

Barème : `the internal bug rubric` (5 points : timeout S3 infini, sweeps chevauchement + isolement, zombies `init: true`, rotation des journaux, chien de garde).
Scripts : `scripts/projn_d.sh` (chaîne scriptée), `scripts/projn_e.sh` (orchestration libre). Un seul essai par bras : variance non mesurée.
| E3 | pipeline à jour + règles anti-agents | ~3,5 | 0,285 $ | +13 |

## Répétition 14/10 (3 essais par bras, juge LLM Sonnet `scripts/projn_judge.py`, ordre tournant, bras Claude seul / D astra medium→Claude / E règles à jour)
Notes /5 (coût Claude $) : A seul 2,5 (0,59) · 3,5 (0,47) · 3 (0,39) → moy 3,0 / 0,48 $. D 4,5 (0,43) · 3,5 (0,33) · 4,5 (0,29) → moy 4,17 / 0,35 $ + astra medium 69-102 k tokens/essai. E 3,0 (0,50) · 3 (0,55) · 2,5 (0,29) → moy 2,83 / 0,45 $.
Lecture : D (analyse astra medium puis Claude) est le seul bras au-dessus de Claude seul (+1,2 pt, moins cher côté Claude) mais coûte de la jauge OpenAI : le lot de 9 essais a fait passer la 5 h de ~23 % à 93 % (hebdo 37 %). E ≈ Claude seul. Juge LLM = un seul juge, ±0,5 ; calibré sur anciens essais.
## T6 bug de concurrence (corpus `scripts/t6`, 2 bugs, grade 0-2) — bras Claude ×3
Sonnet medium 2/2 ×3 (0,12-0,16 $) · Sonnet high 2/2 ×3 (0,14-0,18 $) · Opus medium 2/2 ×3 (0,19-0,50 $). Saturé : Sonnet medium suffit. Bras Codex non lancé (jauge).
## claude plugin eval (deux skills personnels, hors dépôt, 3 runs/cas, ablation)
Avec skill : skill A 3/3, skill B 2/3 ; sans skill : 0/3 et 0/3 ; delta moyen +0,83 ; 1,07 $ au total, 4 min. Les deux skills apportent un vrai gain mesurable.

## T5 lot de 10 tâches bornées (14/10, `scripts/t5/`, graders pytest figés, 140 tests)
- **S** Sonnet medium seul : 140/140, 1,07 $ Claude.
- **C** `cx.sh executant` (sol low) seul : 140/140, 0 $ Claude, jauge 5 h 0→5 % (hebdo 38 %).
- **X** C puis vérification Sonnet medium : 140/140, 1,46 $ Claude (la vérification coûte plus que S entier, sans rien corriger).
- Lecture : saturé, seul le coût départage. Sur tâche bornée à spec précise, Codex seul suffit (le grader automatique remplace la vérification) ; la chaîne X est la pire en coût. Un essai par bras.

## T7 AGENTS court vs long (14/10, `scripts/t7/`, tâche T4 agenda, executant sol low, 3 essais/bras, grader 57 tests)
- aucun : 3/3 à 57/57, ~11 k tokens, checklist suivie 0 fois.
- court (agents_court.md) : 3/3 à 57/57, ~19 k tokens, checklist suivie 3/3.
- long (agents_long.md) : 1/3 à 57/57 (2 essais : TypeError « borne invalide : None » = code cassé), ~27 k tokens, checklist suivie 3/3.
- Lecture : l'AGENTS long coûte ×2,4 en tokens et dégrade (2/3 cassés, n=3 : à confirmer) ; le court ×1,7 pour une discipline sans gain de qualité mesuré. Pour tâches bornées : pas d'AGENTS ou très court. Limite : `~/.codex/AGENTS.md` global chargé dans tous les bras.
