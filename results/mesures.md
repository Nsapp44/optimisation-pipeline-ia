# Mesures d'optimisation des tokens (journal durable)

## Fait
- Projet A : lot 1 (8 offices, labo d'impression, décor) puis lot 2 (racks en bas à gauche,
  palmier et imprimante du coin retirés, jauge 5 h estimée dans le backend : dernière valeur réelle de
  ~/.claude/usage_gauge.json + tokens pondérés depuis, rafraîchie chaque minute, s'arrête avec le projet).
- settings.json : deny (Cron*, RemoteTrigger, PushNotification, NotebookEdit, *Worktree, Agent(general-purpose), Agent(claude)).
  Sauvegarde : settings.json.avant-deny-2026-10-04. CLAUDE.md global : règle « agent le plus léger » + navigateur dans un agent.
- Calibration (Pro, Opus) : 1 point de 5 h ≈ 100 k équivalent Opus ; 1 point semaine ≈ 700 k.
  Poids : entrée 1, cache créé 2, cache lu 0,1, sortie 5 ; Sonnet 0,6, Haiku 0,2. Le compteur a quelques minutes de retard.
  Le cache lu coûte environ 20× moins que le cache créé.
- Mesures : partie fixe CLI 38 k ; deny sans gain tant qu'Artifact reste ; general-purpose 5× plus cher que lecteur/chercheur ;
  le transport entre agents est négligeable ; P3e = 511 k.

- Longueur des sorties (quota/sortie, 1 commande + 4 echo) : sortie Bash 10 Ko entre en entier → +21 k tokens
  (+3 k créé, +13 k lu, ≈ +7 k équivalent Opus, +30 %). Au-delà d'un seuil entre 10 et 19 Ko, le CLI enregistre la sortie
  dans un fichier et ne montre qu'un aperçu de 2 Ko → même coût qu'une sortie courte. Le pire cas est donc ~10-15 Ko par sortie.
- Cache créé au démarrage (quota/cc) : une nouvelle session relit 26,8 k (prompt système + outils, partagé entre sessions
  et dossiers tant qu'il a moins d'1 h) et recrée toujours la suite, ~12,6 k, même deux fois de suite (contenu identique,
  pas d'aléatoire). Détail : CLI seul 4,6 k ; MCP ~3,9 k (surtout les MCP des plugins figma, intercom, atlassian, datadog,
  linear, notion, slack, prisma x2, même non connectés) ; CLAUDE.md global ~2 k + liste de 60 skills ~2 k.
  Piste : désactiver les plugins inutilisés → ~-5 k créés par session ou agent, et -0,5 k équivalent par message.
- Agents (quota/cc/G1, G2) : le préfixe complet d'un lecteur (Haiku) ne fait que 5 k, créé au 1er lancement et relu
  ensuite (2e lecteur : 5 k lus, ~0,5 k créé). Un agent en plus coûte surtout un tour Opus de plus (~+40 k lus) :
  ~6 k équivalent Opus au total, et non 20 à 40 k. Les plugins et MCP pèsent sur le fil principal, pas sur les agents.
- Gros fichier (quota/fic, gros.py de 4 000 lignes ≈ 177 Ko, même question + 3 tours) : lecture entière 625 k
  (cr 83 k, lu 540 k ≈ 220 k équivalent Opus) contre Grep + plages de lignes 233 k (≈ 50 k équivalent) → 4,4× moins.
  Le surcoût est proportionnel au nombre de tours suivants (chaque tour relit le fichier).
- Nouvelle session 1 h après les autres : le préfixe de 26,8 k était encore en cache (gardé chaud par les autres sessions).
- Reprise (quota/exp) : claude -p --resume recrée TOUT l'historique, même tout de suite (49 k créés deux fois de suite,
  seul le préfixe de 26,8 k relu). Le test après 1 h est donc inutile (arrêté). Une session reprise = au prix d'une session
  neuve qui recharge tout son historique. À vérifier : est-ce pareil avec /resume en interactif et dans l'appli ?
- Gros fichier lu par un agent lecteur (fic/A_agent) : ≈ 49 k équivalent, comme Grep ciblé (50 k), contre 220 k pour une
  lecture entière dans le fil principal. Les échanges entre agents ne coûtent presque rien.
- Effort (quota/eff, évaluateur d'expressions, 26 tests cachés, 2 essais par niveau) : medium et high à 26/26 ;
  high = +15 % de sortie, +50 % de réflexion ≈ +1,5 k équivalent par tâche (la sortie ne pèse que ~10 % du coût ici).
  Recherche web : Artificial Analysis (Opus 5.5) donne medium 51 / high 54 / xhigh 56 / max 58 pour 1 / 1,4 / 2,6 / 6,8×
  les tokens. La doc dit que changer d'effort garde le cache sur Opus 5.5 ; MESURÉ FAUX (quota/eff2, pilote.py, une
  session stream-json, CLI 2.1.289, opus-5-5) : après « /effort high », 51,6 k recréés (tout l'historique) ; témoin
  « /effort medium » (même niveau) : 0,2 k. Changer d'effort = recréer tout le contexte. Pas de passerelle (BASE_URL api).
- /compact (eff2/K2_compact, --debug-file : ligne « Forked agent [reactive-compact] ») sur 78 k de contexte :
  l'appel de compaction RECRÉE l'historique (cr 48,8 k, lu 26,8 k, in 4,7 k, out 0,6 k) ≈ 108 k équivalent, puis
  8,7 k recréés au tour suivant. Contexte ensuite 35,8 k au lieu de 78 k → gain 4 k éq/message, rentable après ~25 messages.
  Nouvelle session + note de passation ≈ 30 k éq → bien moins cher que /compact. L'autocompact (même mécanisme ?) à
  ~130 k coûterait ~250-300 k éq (non mesuré).
- Consigne d'agent (quota/brief, dépôt projet A, question jauge 5 h) : agent lecteur consigne vague 91 k éq (Sonnet 37 k),
  consigne précise (fichiers + lignes + « 10 lignes max ») 67 k (Sonnet 20 k), sans agent 87 k (9 tours). Une consigne
  précise divise par ~2 le coût de l'agent ; le fixe d'une session Opus neuve (~45 k) domine sur une petite question.
- Jauge : 4 % → 18 % pour ~1 M éq de tests (≈ 70-100 k éq par point, calibration confirmée).
- Projects (bêta 17/09/2026, code.claude.com/docs/en/claude-projects) : un coordinateur lance des threads cloud en
  parallèle (mémoire de projet partagée, chaque thread = session complète). Défaut : threads Opus high, coordinateur low
  → baisser dans Project settings > General. Use les limites plus vite (surtout Pro). Thread inactif > 1 h relancé = relit
  tout son historique → préférer un nouveau thread. Onglet Usage par thread et par modèle.


## Reste (au 05/10, mesures incluses)
- FAIT (05/10) : CLAUDE.md global mis à jour (changer d'effort/modèle recrée le cache ; agent ≈ 6 k éq).
- À tester : Projects (Chrome non connecté, pas d'outil pour créer un projet → l'auteur doit l'ouvrir ou connecter Chrome) ;
  autocompact réel ; /resume dans l'appli.
- Jauge (05/10 10:00) : réel 19 % ; tokens locaux depuis 09:00 = 1,19 M éq → 62 k/point (calib. 70-100 k).
  Écart possible : thread Projects (cloud, absent des journaux locaux) ou chats claude.ai. La statusline
  (hooks/conso_5h.py) ne tourne pas dans l'appli → usage_gauge.json périmé si on n'utilise que l'appli.
  Outil : quota/fenetre.py <epoch> = tokens pondérés par demi-heure.
- Reprise dans l'appli (05/10, appli quittée puis rouverte ~1 min, contexte 75 k) : 1er tour cc 1,7 k, cr 75 k
  → cache GARDÉ (contrairement à claude -p --resume). Reprendre une session récente (< 1 h) dans l'appli est sans surcoût.
- Durée du cache : fil principal 1 h, agents 5 min (mesuré : 6,1 M créés en 5m, 0 en 1h). Sans effet car les tours
  d'un agent se suivent en secondes ; seul risque : agent qui attend > 5 min une commande longue.
- 05/10 : deny Agent(Plan) ajouté (sauvegarde settings.json.avant-plan-2026-10-05). Test en cours :
  <PROJECT_DIR>/.claude\settings.json enabledPlugins=false (design, searchfit-seo, prisma ; clés devinées) → nouvelle
  session de test : les skills design:/searchfit-seo: ont-ils disparu ? mesurer cc au 1er tour (réf. 12,6 k).
- Piste : settings modelSettings "claude-sonnet-5" effort xhigh — s'applique-t-il aux agents Sonnet (5-5) ?
- Autocompact : ne pas le provoquer, le mesurer quand il arrive tout seul.
- Agents spe- : résumé du projet Project R reçu et propositions faites
  (script de recettes, agent cas à la main, agent docs). Fichiers d'agents à écrire si l'auteur valide.
- Worktrees opt-a/b/c supprimés.
- Outils : <PROJECT_DIR>/anatomie.py <dossier projet> [n] ; quota/batch_R.sh, batch_C.sh ; parser le JSON du CLI à partir du premier {.

## 05/10 (suite) — pauses des agents et plugins par projet
- Pause agent CONFIRMÉE (Haiku, pause 6 min 43) : tour suivant cc 13,7 k, cr 0 → tout le contexte de l'agent recréé.
- PC Project R (quota/pauses_agents.py) : 17 agents, 835 tours ; 4 tours après une pause > 5 min (0,5 %) mais
  949 k recréés sur 4 399 k de cc des agents (22 %), ≈ 237 k par tour (agents à gros contexte). Surcoût ≈ 949 k ×
  (1,25 − 0,1) ≈ 1,1 M éq. entrée. Durées d'agents : médiane 11 min, max 49, 2/17 > 30 min (pas des agents de 6 h).
  → Règle utile : un agent n'attend jamais > 5 min une commande ; il la lance, rend la main, un nouvel agent analyse.
- enabledPlugins=false dans .claude/settings.json du projet : SANS EFFET. Les clés étaient pourtant les bonnes
  (vérifiées dans ~/.claude/plugins/synced/<compte>/manifest.json) : les plugins synchronisés depuis le compte
  claude.ai ignorent ce réglage → skills design:/searchfit-seo:/engineering: et MCP prisma toujours chargés.
  Pour les retirer : les désactiver côté claude.ai (Customize > plugins), pour tous les projets.
- Reste : réglage cache 1 h pour les agents ? ; modelSettings "claude-sonnet-5" effort xhigh appliqué aux agents
  Sonnet 5.5 ? ; test A/B longue session vs passation ; autocompact réel ; Projects.
- Cache 1 h des agents (05/10) : réglage `subagentPromptCacheTtl: "1h"` (settings) ou env
  CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL=1h, ou frontmatter `experimental: cacheTtl: 1h`. TESTÉ : agent écrit tout en
  ephemeral_1h. NON ACTIVÉ : l'écriture 1 h coûte 2× contre 1,25× ; sur Project R +≈2,6 M éq. pour ≈1,1 M économisés
  → perte. La règle « un agent n'attend jamais > 5 min » (CLAUDE.md global) suffit.
- modelSettings et agents (05/10) : s'applique bien aux sous-agents (journal de l'agent : "effort":"low"/"xhigh" ;
  réflexion sur un même calcul : low 4,9-5,1 k, xhigh 7,8-11,3 k). MAIS la clé globale "claude-sonnet-5" ne
  touche pas Sonnet 5.5 : avec elle, l'agent tourne en "effort":"medium". Clé correcte : "claude-sonnet-5-5".
  Frontmatter d'agent : champ `effort` documenté (prime sur la session). Tests : quota/ttl/.
- 05/10 : settings.json global corrigé → "claude-sonnet-5-5": effortLevel medium (vérifié : agent executant = claude-sonnet-5-5, "effort":"medium"). Cache agents laissé à 5 min.
- Bugs de cache connus (recherche 05/10, à revérifier) : #34629 (-p --resume, fermé) ; #41930 + post-mortem
  Anthropic 23/04/2026 (corrigé 2.1.116) ; OUVERTS proches de 2.1.289 : #99096 (cache_read=0 en pleine boucle
  d'outils, task_reminder/output_style injectés), #96578 (corrigé par CLAUDE_CODE_DISABLE_AUTO_MEMORY=1), #84253.
  Outil tiers : github.com/cnighswonger/claude-code-cache-fix (MIT) = proxy local :9801 via ANTHROPIC_BASE_URL ;
  voit token + échanges ; ne couvre pas #99096 ; compat appli desktop / Windows inconnue.
- Cassures de cache (quota/cache_casse.py, 14 j) : fil 831 tours, cc 6 190 k ; pause > 1 h 23 %, chgt effort 7 %, inexpliquées 4 % (surtout sessions de test -p) → pas impactés, proxy cache-fix inutile. Règle « pause > 1 h » ajoutée au CLAUDE.md global. Config stable : docs/config-stable.md.

## 05/10 — Sonnet 5.5 en modèle principal (claude -p, effort medium, tests cachés)
- Évaluateur d'expressions (26 cas) : Sonnet 26/26 ×2, 56,0 k et 26,9 k éq. Opus ; Opus medium 26/26, ~101 k.
- Lecteur CSV RFC 4180 étendu (25 cas + 8 erreurs, quota/eff3) : Opus 33/33 ×2 (51,5 / 52,1 k), Sonnet 33/33 ×2
  (27,1 / 27,4 k). cc identiques (~15,5 k), Sonnet sort moins de tokens.
- Conclusion : Sonnet par défaut (-45-50 %), Opus en conversation d'architecture ou agent `architecte` (Opus high).
  Limite : tâches bien spécifiées ; l'écart d'Opus sur la conception floue n'est pas mesuré ici.
- Vérif réglages (quota/archi, claude -p sans --model) : fil en claude-sonnet-5-5 (défaut OK), agent `architecte` en
  claude-opus-5-5 effort high (frontmatter OK). Coût architecte (plan LRU+TTL, 1 tour) : cc 13,1 k + sortie 1,1 k
  ≈ 32 k éq. Opus ; fil Sonnet ≈ 35 k éq. ; tâche finie.
- Pipeline sur la tâche CSV (coût $ réel claude -p) : Sonnet seul 0,09 $ ; Opus seul 0,19 $ ; Sonnet + architecte
  0,20 $ (Sonnet 0,126 + Opus 0,077) ; tous 33/33. Sur une tâche facile l'architecte n'apporte rien et coûte ~0,08 $ :
  à réserver aux points durs ; le gain vient de Sonnet sur tous les autres messages (~-50 %).
- Advisor : non mesurable en claude -p (Sonnet ne l'appelle pas, aucun usage advisor). À mesurer dans l'appli.
- Tâche longue et dure (mini-tableur : grammaire, fonctions, plages, cycles, erreurs, perf ; 73 contrôles, quota/tab) :
  Opus medium 0,45 $ / 0,38 $ ; Sonnet 0,18 $ / 0,19 $ ; Sonnet + architecte au départ 0,61 $ (Opus 0,26).
  Notes 72-73/73 partout ; les 3 points perdus viennent de 2 phrases ambiguës de ma consigne (« espaces ignorés » →
  "=3 4" = 34 chez Opus ; ordre texte/erreur dans "=B1+A1" chez les 2 Sonnet), interprétations défendables.
  Sonnet n'a pas appelé l'architecte (jamais bloqué). → Sonnet -55 % à qualité égale sur tâche longue bien spécifiée ;
  architecte d'office = le plus cher sans gain. Non mesuré : demande floue / conception ouverte.

### 05/10 — Demande floue + débogage multi-fichiers (quota/bug)
Mini-boutique en 5 fichiers, 9 bugs (arrondi tronqué, dict par défaut partagé entre paniers, retrait > quantité,
casse des codes promo, date de fin exclue, remise fixe après TVA et sans plancher, commande pas « tout ou rien »,
double annulation). Consigne vague (« des clients signalent des problèmes… »), règles dans README.md, 28 tests cachés.
| Essai | Note | Coût |
|---|---|---|
| Opus medium ×2 | 28/28, 28/28 | 0,35 $ / 0,286 $ |
| Sonnet medium ×2 | 28/28, 28/28 | 0,13 $ / 0,126 $ |
→ Sonnet −60 % à qualité égale ; aucune escalade. Test trop facile pour séparer les modèles (spécification écrite).

## 05/10 — Rejeu d'une vraie enquête (Project N, « le conteneur plante après plusieurs jours »)

Code au commit `7f0d350` (juste avant le correctif), lecture seule (`Agent,Read,Grep,Glob`), sans prod ni logs.
Notation sur les 5 points du vrai correctif `1a1de03` + `7206672` : timeout S3 infini, sweeps (chevauchement +
isolement des erreurs par élément), zombies (`init: true`), rotation des journaux, chien de garde.

| Essai | Coût | S3 | Sweeps | Zombies | Journaux | Garde | Note |
|---|---|---|---|---|---|---|---|
| opus_1 | 1,21 $ | ✗ | ✓ | ✓ | ✗ | ✓ | 3 |
| opus_2 | 1,67 $ | ✗ | ½ | ✓ | ✗ | ✓ | 3 |
| sonnet_1 | 0,61 $ | ✗ | ½ | ½ | ✓ | ✓ | 2,5 |
| sonnet_2 | 0,83 $ | ✗ | ½ | ✓ | ✓ | ✓ | 3,5 |
| pipe_1 (Sonnet + contre-expertise architecte) | 1,81 $ (Sonnet 0,87 + Opus 0,94) | ✗ | ✗ écarté | ½ écarté | ✓ | ✓ | 2,5 |

- Moyennes : Opus 3/5 pour 1,44 $ ; Sonnet 3/5 pour 0,72 $. Variance d'un essai à l'autre aussi grande que l'écart entre modèles.
- Opus va plus profond (mécanisme exact des zombies, liste de devis qui grossit) ; Sonnet est plus large (journaux).
- pipe_1 : l'architecte a **écarté à tort** deux vraies causes (« S3 borné à 15 s » : c'était justement le bug,
  `requestTimeout` sans `throwOnRequestTimeout` ne coupe pas ; orphelins jugés rares). Plus cher qu'Opus seul, moins bon.
- Personne ne trouve le timeout S3 : il fallait une reproduction réelle. Le gain du 03/10 venait de l'accès à la prod.

**Conclusion** : Sonnet par défaut confirmé, même sur une enquête floue. `architecte` sert à débloquer ou trancher une
décision, pas à « relire un diagnostic » (il élague avec assurance, y compris de vraies pistes). Pour une enquête de
panne, le levier est la mesure (logs, repro), pas le modèle.

## 05/10 — Délégation spontanée, audit sur gros projet, architecture floue (quota/brief, quota/gros)
- Petites questions (lire 3-7 fichiers, projet A) : Sonnet et Opus ne lancent AUCUN agent (0/4). Sonnet 32-48 k éq., Opus 112-125 k.
- Très gros audit (projet A, sans mention d'agents) : Sonnet 2 × `lecteur` (Haiku) 0,48 $ ; Opus 3 × `lecteur` (lancés en Sonnet) 1,21 $.
- Audit avec 7 bugs plantés (copie quota/gros, 2 essais par modèle) : Sonnet 4 et 6 trouvés (0,94 / 1,00 $), Opus 4 et 3
  (2,34 / 2,42 $). Délégation à `lecteur` des deux côtés (Sonnet 2-3, Opus 3-4). Écart de qualité dans le bruit ; Sonnet ÷2,5.
  Personne n'a trouvé le bug de `compress_path` (texte tronqué trop long).
- Architecture floue (« serveur partagé pour plusieurs développeurs », 2 essais) : aucun agent, ni Sonnet (0,36 / 0,35 $) ni Opus
  (0,59 / 0,57 $). Plan d'Opus un peu plus fin (file locale, événements idempotents, bugs plus profonds).
- Avec la règle « consulte `architecte` avant le plan » : Sonnet l'appelle bien (1×) mais coût 0,91 / 1,61 $ (architecte
  280-560 k éq. : il explore tout lui-même) → 2-3× Opus seul. Règle ABANDONNÉE.
- Politique retenue : Sonnet ~80 % ; doute ou conception floue → SUIVI.md + conversation Opus (medium, ultracode si majeur) ;
  l'auteur absent → `architecte` en medium sur le point précis ; high seulement sur demande.
- Limites : 2 essais par cas, notation par lecture des rapports, tâches de code.

### 05/10 (suite) — Comparatif gros, config finale (Sonnet medium, architecte medium, advisor non testable ici)
| Run | Tâche | Agents | Coût | Résultat |
|---|---|---|---|---|
| NA_1 | architecture floue | 0 | 0,31 $ | plan complet, 0 appel architecte |
| NA_2 | architecture floue | 0 | 0,39 $ | plan complet + recommande ultracode (conforme à la règle) |
| NB_1 | audit 7 bugs | — | 0,15 $ | INVALIDE : limite de session atteinte |
| NB_2 | audit 7 bugs | 0 | 0,45 $ | 0/7 bugs plantés : périmètre annoncé (api/, git_service, pollers…), n'a pas lu les fichiers plantés ; a trouvé d'autres vrais défauts |
Conclusions : Sonnet ne délègue pas à architecte de lui-même (confirmé 2/2) ; sur audit, un seul run valide, trop peu pour comparer avec l'ancien (Sonnet 4-6/7 ~1 $, Opus 3-4/7 ~2,4 $) ; le résultat dépend de quels fichiers il choisit de lire.

### 05/10 (validation) — Audit 7 bugs plantés, même prompt, 3 Sonnet + 3 Opus (medium, quota/brief/VS_*, VO_*)
| Run | Bugs trouvés /7 (notation stricte, lignes citées) | Coût | Agents |
|---|---|---|---|
| VS_1/2/3 | 3 / 5 / 4 (moy. 4,0) | 0,89 / 1,00 / 1,06 $ (moy. 0,98) | 0 |
| VO_1/2/3 | 7 / 5 / 4 (moy. 5,3) | 1,60 / 3,11 / 2,63 $ (moy. 2,45) | 0 / 4 lecteur / 4 lecteur |
Lecture : Opus un peu meilleur en moyenne (+1,3 bug) mais très variable (4 à 7), pour 2,5× le prix. Sonnet : 4 bugs pour ~1 $.
Coût par bug trouvé : Sonnet 0,25 $, Opus 0,46 $. Les NB (0,45 $, 0/7) étaient un run « paresseux » hors périmètre : prompt trop vague.

### 05/10 (session normale) — config réelle sans réglage forcé (modèle/effort par défaut = Sonnet medium), chantier audit + correction (quota/brief/N_session.json)
1,41 $, 5 tours, 1 × lecteur, 0 architecte, 0 SUIVI. 5 bugs corrigés dont 2 plantés sur 7 (token_tracker, usage_service) ; 3 autres corrections non vérifiées (pas de tests lancés) ; 4 « doutes sérieux » listés sans deviner (conforme à la règle) ; fichiers non lus listés. 1 seul run : pas de moyenne.
Comparé : audit seul Sonnet ~1 $ (3-5/7), Opus 2,45 $ (4-7/7). Ici la correction s'ajoute (+0,4 $) mais la couverture des plantés est plus faible (2/7) : il a audité large et a lu peu des fichiers plantés.
