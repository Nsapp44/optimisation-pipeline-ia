# Consignes générales de Nolann (toutes les sessions Claude Code)

## Économie de tokens et modes d'effort

- **Me dire quel mode d'effort il faut** quand la nature du travail change (une ligne « mode conseillé : … »). Je
  change le mode moi-même.
  - **medium** : **par défaut partout** (questions, explications, code ciblé, corrections).
  - **élevé (high)** : seulement si je le demande (mesuré : Sonnet medium = high en qualité, high ~1,6× plus cher).
  - **ultra (ultracode)** : **seulement pour les problèmes extrêmement complexes** qui ont besoin de beaucoup d'agents
    en parallèle (architecture, gros chantiers multi-fichiers avec relecture croisée). Repasser à un mode plus léger
    dès que c'est fini, et me le dire.
  - **Au début de chaque nouveau projet, me rappeler de passer en ultracode pour l'architecture**, puis me dire de
    redescendre en élevé dès qu'elle est posée.
- **Modèle principal : Sonnet 5.5 par défaut** (mesuré : même note qu'Opus, ~45-50 % moins cher). **Opus seulement
  dans une conversation dédiée** à un gros travail d'architecture ou à un problème très dur (choisi au démarrage,
  jamais en cours de conversation).
  - **Advisor (rétabli le 26/10/2026, compte Max)** : si l'outil `advisor` est dans la liste de la session, **appel OBLIGATOIRE (durci le 29/10/2026 : aucun appel trouvé dans les transcriptions des sessions)** sur un gros chantier / travail important : 1 avant de figer l'approche, 1 avant « fini » (livrable écrit/commité d'abord) ; et dès que ça galère (même erreur 2 fois). Dire « advisor : appelé » ou « non appelé, raison » dans le rapport final. Jamais à chaque étape ni pour un geste court ou une petite tâche. **S'il est absent (compte Pro/travail), pas d'advisor** : le jugement dur passe par l'agent `architecte` (Opus **medium**), consigne courte : but, fichiers, ce qui est douteux ou essayé + erreur exacte ; puis Sonnet applique son plan. `architecte` reste aussi pour les déclencheurs 1-6. Pas pour « relire un diagnostic » ni pour tout un plan.
  - **Qui fait quoi** : ~80 % du temps Sonnet. Si Sonnet doute, ou si la demande est une conception floue / un
    changement important : **il s'arrête, écrit `SUIVI.md` (but, contexte, ce qui est connu) et me dit d'ouvrir une
    conversation Opus** (medium pour un changement important, ultracode pour un changement majeur d'architecture).
    Opus finit par un SUIVI à jour et me dit « clair, repars sur Sonnet » (nouvelle conversation).
  - **Déclencheurs d'`architecte`** (ne pas attendre de « se sentir bloqué ») : 1) un test échoue encore après 2
    corrections ; 2) une liste de « doutes sérieux » ou « non vérifié » → confier le plus important à `architecte`
    avant de rendre le rapport ; 3) des fichiers « non lus » dont dépend la conclusion → les lire avant de conclure,
    ou le dire en tête du rapport ; 4) aucun progrès sur 2 points d'étape, ou la même trace d'erreur qui revient ;
    5) contradiction test/doc, module difficile à concevoir ; 6) **design/visuel sans base** (SVG, README, écran) ou **plus de 2 allers-retours avec Nolann sur le même rendu** → `architecte` conçoit et vérifie par captures, pas de retouches Sonnet en boucle. **Son plan ne doit exiger que des commandes que la session
    peut lancer (pytest…), avec un repli ; si une commande est refusée, Sonnet s'adapte, il ne s'arrête pas** (bancs
    T9 16/10 : sinon 0/5). Sans déclencheur, Sonnet seul (C coûte 1,6× A sans gain mesuré).
  - **Si je suis absent** : Sonnet ne reste pas bloqué ; il appelle `architecte` (medium) sur le point précis, puis
    continue. High seulement si je le demande.
  - **Changer d'effort ou de modèle en cours de conversation recrée tout le cache** (≈ 2 × le contexte) : changer
    tant que la conversation est courte ; sinon nouvelle conversation avec note de passation (≈ 15 k).
- **Sous-agents, gradués selon la tâche**, **quel que soit le mode** : **Haiku** (`model: "haiku"`) pour le très
  simple et mécanique (chercher, lister, relever, compter, renommer, mettre en forme, lancer une commande et rapporter
  sa sortie) ; **Sonnet** (`model: "sonnet"`) pour tout le reste de l'exécution (code d'une partie déjà conçue,
  recherches, lectures et analyses, tests, corrections ciblées) ; **le modèle principal** garde conception,
  arbitrages, synthèse et vérification finale. Seul agent Opus autorisé : `architecte`.
- **Nombre d'agents** : 1 à 3 pour une tâche ordinaire (dès qu'un seuil de délégation est atteint, on lance l'agent) ;
  **3 à 6 en parallèle pour un gros chantier aux morceaux indépendants** ; **jusqu'à 8-10 si je demande l'efficacité /
  la rapidité**, ou en ultracode. Jamais deux agents qui écrivent dans le même fichier. Pas d'agents *inutiles*.
- **Choisir l'agent le plus léger** : recherche web → `chercheur` ; lecture de 3 fichiers ou plus (ou ~300 lignes) →
  `lecteur` ; tests/lint/captures/commandes longues → `testeur` (Haiku, ne modifie rien) ; écrire ou modifier du code
  décidé → `executant` (`general-purpose` et `claude` interdits dans settings.json : 5× plus chers). **Regrouper les
  appels d'outils indépendants dans un même tour.**
  **Relectures sur demande (Sonnet medium, lecture seule, jamais automatiques)** : erreurs silencieuses Python/Qt/JS →
  `chasseur-erreurs` ; avant mise en ligne web (secrets, XSS, CSP) → `securite-web` ; référencement → `seo`.
  **Scan de sécurité complet (plugin `claude-security`, activé 29/10/2026)** : lancé depuis le fil principal, jamais par un agent, avant toute mise en production et sur tout livrable fini, avant de le donner à tester ; coûteux, donc pas à chaque commit.
  **Consigne de revue de code** (à coller dans le prompt) : ne signaler que si sûr à plus de 80 % ; pour
  HIGH/CRITICAL, citer ligne + scénario d'échec concret + pourquoi rien ne le rattrape, sinon baisser ou abandonner ;
  « aucun constat » est valide ; pas de remarques de style ni de « pensez à X » ; format `[GRAVITÉ] chemin:ligne` /
  problème / correction, puis tableau récapitulatif.
  **Contrat de fin de délégation** : le message final d'un agent EST son livrable (jamais « j'attends les autres
  agents »). `executant` : diff minimal, ni renommage ni refactor hors consigne ; il s'arrête après 3 mêmes erreurs ou
  si son correctif en crée plus qu'il n'en règle. `lecteur` en recherche ouverte : 3 cycles au plus, chaque fichier
  noté de 0 à 1, ne rendre que ceux ≥ 0,7.
- **Règles d'agents (24/10/2026, retours des sessions)** : `chercheur` indisponible → WebSearch/Explore en direct, mêmes 15 recherches ; une licence = 2 sources. Jamais `kill`/`taskkill` de tous les `python.exe` dans un prompt (cibler le PID). `testeur` diagnostique avant de conclure « échec » (réglages par défaut, accents normalisés) et contrôle TOUT le lot (5 images sur 5). Rendu long : la commande de fin prévient aussi si le processus s'arrête avant la fin.
- **Rafale / dictée (24/10/2026)** : 1re ligne de réponse « j'ai compris : 1… 2… 3… », ajouté à la file de SUIVI.md ; doute = pop-up. **Lot d'interface** : lire `web-design-guidelines` + `design:design-critique`, recopier la checklist dans le brief `executant`/`architecte` (qui n'a pas l'outil Skill), et je regarde les captures avant « fait ».
- **Geste d'une ligne** (commande courte, retouche < ~30 lignes) : pas de délégation ni d'annonce d'agent.
- **Délégation lecture / écriture / tests : OBLIGATOIRE.** Le fil principal **conçoit, tranche et vérifie** ; il ne
  fait pas l'exécution. Avant CHAQUE Read / Edit / Write / lancement de tests : « un agent peut-il le faire ? ».
  - **Écrire du code déjà conçu** (classe, fonction, bloc de tests, doc > ~30 lignes) → `executant` avec consigne
    précise (fichier, signatures, comportement, contraintes, ce qu'il rend). Le fil principal n'écrit que les petites
    retouches (< ~30 lignes) et la colle.
  - **Lire** : ≥ 3 fichiers ou ~300 lignes → `lecteur` (Haiku), sans exception.
  - **Tests / captures / commandes longues** → `testeur`, qui rapporte seulement verts / rouges + échecs utiles.
  - **Seuil** : un agent recrée ~20-30 k de cache au démarrage (mesuré 10-22 k le 12/10 ; 30-95 k et plus pour un agent qui lit beaucoup) ; il ne vaut le coup que s'il évite au fil principal
    **plus de ~30 k** de lecture ou de sortie. **Fil principal** : 1 ou 2 commandes courtes (sortie < ~50 lignes,
    coupée par head / grep), un contrôle ponctuel, un grep ciblé, un petit script de vérification. **Agent** : suite
    de tests complète, sorties longues, plusieurs captures, gros fichiers, code > ~30 lignes. Un seul agent pour un
    lot de contrôles, jamais un agent par commande.
  - **Recherche web** → toujours `chercheur`, jamais en direct.
  - **Le fil principal relit la diff / l'extrait clé** de ce qu'un agent a écrit avant de dire « fait » (jamais
    d'aveugle) et l'écrit dans le rapport. Écrire soi-même un gros bloc qu'un agent aurait pu faire = faute.
  - Dire à Nolann, en une ligne à chaque lancement, quel agent et pour quoi (« lecteur : lit X »).
- **Navigateur (captures, pages longues) dans un agent** dès plus de 2-3 captures.
- **Un agent n'attend jamais plus de 5 min** (son cache dure 5 min) : il lance la commande longue en arrière-plan,
  rend la main avec ce qu'il a lancé et où lire le résultat ; un nouvel agent l'analyse. La durée n'est pas un critère
  d'arrêt ; ce qui coûte : une pause > 5 min et un contexte qui grossit. Donc **une consigne = un seul livrable** ;
  **pas de boucle « je construis, je capture, je regarde » dans l'agent qui construit** (vérification visuelle à part) ;
  lire des extraits plutôt que des fichiers entiers ; **vers 30 appels d'outils, faire le point et rendre ce qu'on a**.
  **Plafond de lecture par agent : ~100 000 caractères (≈ 30 k tokens) de résultats d'outils.** Au-delà, scinder en
  plusieurs `lecteur` en parallèle, chacun sur un sous-ensemble distinct (dossiers ou fichiers différents), rapport ≤ 30
  lignes chacun ; un agent qui lit 270 k caractères a écrit 160 k tokens de cache (mesuré 12/10), deux agents de moitié
  coûtent moins qu'un seul gros (chaque message relit tout son contexte), ~15 k de démarrage en plus chacun.
- **Un agent qui galère demande conseil** : même erreur 2-3 fois, approche qui ne converge pas, doute sur ce qu'on
  attend de lui → il s'arrête et rend la main avec le point de blocage (ce qu'il a essayé, ce qu'il propose) ; le
  principal tranche (`architecte` si besoin) et le relance, en passant au modèle du dessus (Haiku → Sonnet) si besoin.
  L'écrire dans le prompt de chaque agent.
- **Planifier / relancer un travail (tests, builds, commandes) = Planificateur de tâches Windows via PowerShell**
  (`schtasks` / `Register-ScheduledTask`, script `.ps1` plutôt que commande inline), car les routines de l'appli
  bloquent sur les autorisations. **Exception (décidée 17/10/2026) : les rendez-vous réguliers de veille ou de point
  (mensuel, hebdo : point mensuel pipeline) = routine Claude**, visible dans « Scheduled » ; lecture et
  rapport seulement, aucune action risquée. Pas de skip des permissions ; dire à Nolann ce que la tâche lance.
  **Routine Claude (vérifié 20/10)** : chaque run = une vraie session locale, dans le dossier du projet où la routine a été créée
  (le créer depuis la conversation du projet concerné), listée dans « Tâches planifiées », archivable ; pas de réglage de dossier ni
  d'autorisations dans l'outil ; jamais créée en mode Auto sans l'accord de Nolann.
- **Pas d'agent de surveillance** : attendre les notifications de fin, ne jamais faire tourner un agent ou une boucle
  qui vérifie « c'est fini ? ». Point d'avancement = une commande courte quand on me le demande ; longue attente
  (plusieurs heures) = script ou tâche planifiée Windows, sans tokens. **Pas de Monitor qui notifie à chaque ligne de
  progression** : **un seul réveil à la fin** (commande en arrière-plan qui attend la fin, puis affiche la queue du
  log). Monitor seulement pour les erreurs et la fin ; ne rien écrire entre deux réveils.

## Contexte court (les « cache reads »)

- **File des demandes (24/10/2026)** : Nolann parle beaucoup et enchaîne les demandes ; sans plan écrit, des tâches se perdent. **Chaque nouvelle demande s'ajoute à la section « File des demandes » de `SUIVI.md`** (liste numérotée, cochée) AVANT d'être traitée ; je finis la tâche en cours, je coche, je redis la file restante en une ligne, puis la suivante. Jamais lâcher une tâche pour la dernière phrase reçue ; si la file dépasse ~6 points ou se mélange, **je m'arrête, je la restructure (regrouper, ordonner, dire ce qui est fait/en cours/à faire) et je la montre**. Nouvelle demande qui change le plan = je refais le plan, pas de coupe silencieuse. Une demande abandonnée volontairement est écrite comme telle, avec la raison. **Gros chantier ou rafale de messages : j'utilise le mode plan (EnterPlanMode) au départ et à chaque ajout important, comme avant.**

- **Doute = pop-up (24/10/2026)** : Nolann ne lit pas toujours le texte. Dès qu'une demande est floue, ambiguë ou qu'un choix lui appartient, j'utilise l'outil `AskUserQuestion` (pop-up, 2-4 options, ma recommandation en premier), jamais une question noyée dans le texte. Pendant qu'elle attend, je continue le reste de la file.
- Chaque message relit **toute** la conversation. Compaction automatique à **160 000 tokens** (27/10/2026 ; 130 000 bouclait, le contexte repart à ~110 k après compaction ; hook `boucle_compact.py` détecte 2 compactions en < 15 min : **Claude fait alors la passation seul (skill `passation`, mode autonome), sans demander** ; hook PreCompact à 10 s) (`autoCompactWindow`
  dans `~/.claude/settings.json`). Me proposer `/clear` ou une nouvelle session (avec note de passation) quand on
  change de sujet ; ultracode seulement le temps du chantier. **Fin de sujet (17/10/2026)** : dès qu'un sujet est
  terminé (SUIVI.md à jour) et que ma demande suivante est d'une autre nature, AVANT de commencer, dire en une ligne
  « nouvelle conversation conseillée, modèle/effort : X » et attendre mon choix ; un détail à corriger sur le sujet en
  cours se finit ici. Sujet lié qui a besoin du contexte : nouvelle conversation quand même, SUIVI.md porte le contexte. **Compaction stratégique** : proposer `/compact` aux
  frontières naturelles (fin d'une recherche avant de planifier, plan écrit dans un FICHIER avant d'implémenter,
  débogage terminé, approche ratée abandonnée), jamais en pleine implémentation. Avant : SUIVI.md à jour (todos et
  raisonnement intermédiaire ne survivent pas ; CLAUDE.md, fichiers et git oui).
- **Coût fixe** : base ≈ 78 k tokens relus à chaque message (outils ≈ 39 k, MCP ≈ 21 k, CLAUDE.md ≈ 8 k, mesuré
  11/10) → garder ce fichier court, ne pas ajouter de serveur MCP sans besoin ; mon accord avant de retirer/désactiver
  un MCP ou de toucher aux réglages.
- **Changement de conversation pendant un chantier (assoupli le 26/10/2026)** : pas de `/clear` ni de changement de modèle en plein travail. Mais **un lot fini = point de passation possible** si les 3 sont réunis : 1) lot terminé ; 2) `SUIVI.md` réécrit propre (décisions en vigueur, liste des OK validés, le « pourquoi » des décisions orales, prochain pas) ; 3) script de non-régression vert (rebuild + contrôles + comparaison aux références validées ; à créer si le chantier a des rendus à ne pas casser, et à relancer dans la nouvelle conversation). Alors dire « point de passation propre, nouvelle conversation conseillée » ; l'utilisateur choisit. Script rouge ou SUIVI.md incomplet = on reste. Si l'utilisateur dit qu'il s'absente, ne pas demander de changer de conversation. Les détails de code ne sont pas dans SUIVI.md : on les relit à la demande.
- **Pause de plus d'1 h = cache du fil perdu** (reprise = 2 × le contexte). Le hook `hooks/pause_longue.py` bloque le
  1er message après > 1 h si contexte > 80 k (renvoyer = on continue et on paye). Si je dis « pause », écrire SUIVI.md
  avant que je parte.
- **`SUIVI.md` = ÉTAT COURANT seulement** (viser ≤ ~5 Ko, jamais d'accumulation ; **lu UNE fois** au démarrage, après compaction ou grosse pause, jamais
  entre deux messages ; hook `hooks/suivi_taille.py` alerte > 8 Ko, une fois par conversation) : décisions en vigueur, état actuel, **« Ce qui n'a pas marché et pourquoi »**, **« Prochain
  pas exact »** (section vide = « rien pour l'instant », on ne la supprime pas). **RÉÉCRIT (pas complété)** à chaque
  étape ou décision, sans que je le demande. **Règle dure : AVANT chaque compte rendu à Nolann et à la fin de chaque
  étape terminée, SUIVI.md est réécrit propre (état, prochain pas exact) ; jamais de réponse avant.** Le hook de pause
  1 h bloque le message de reprise : s'il n'est pas propre à ce moment-là, on perd le fil (vécu 12/10). **Un SUIVI par chantier**, chargé seulement par la session de ce chantier. **Zéro perte à l'allègement (test : 1 info introuvable sur 10)** : on DÉPLACE sans réécrire (copie `.bak` avant, l'archive garde le texte d'origine) ; le SUIVI court garde les valeurs exactes, les listes ordonnées et un **index des archives** (sujet → fichier, section) ; contrôle avant de conclure : 10 questions tirées de l'ancien SUIVI, toutes retrouvables dans court + archives. Ce qui est fini et son détail vont dans `docs/` (archives, journal, spec)
  avec un renvoi d'une ligne. Même règle dans chaque projet, avec la règle de docs techniques du projet. Après
  compaction ou pause, le relire d'abord. **Note de passation lue par une nouvelle session = supprimée** une fois
  reprise (résultats durables dans `docs/`).
- Contexte léger : ne lire que les parties utiles, couper les sorties longues (head / tail / grep), faire lire les
  gros fichiers et journaux par un agent qui ne rapporte que la conclusion, rapports d'agents courts, mémoires courtes.
- **CLAUDE.md d'un projet : ~15 Ko maxi (≈ 150 lignes de 100 caractères)**, seulement ce qui sert à chaque message
  (règles et pièges, décisions à construire, où trouver le reste) ; le fait et son détail vont dans `docs/`. Un hook
  (`~/.claude/hooks/claude_md_taille.py`) signale un CLAUDE.md trop gros ; je lance alors le skill `menage-claude-md`
  (agent Opus) à la fin de la tâche.
- **Docs d'abord** : lire la doc du projet (README, CLAUDE.md, docs/, audits) avant le code. Chercher (Grep/Glob) avant
  de lire. Dès 3 fichiers, ou ~300 lignes cumulées, ou exploration de dossier → agent `lecteur` (Haiku), consigne
  précise (ce qu'on cherche, ce qu'on veut en retour : signatures, valeurs, extraits) et rapport court. **Le fil
  principal ne lit que** : le fichier qu'il va modifier juste après (partie utile, offset/limit), ou un extrait ciblé
  trouvé par Grep. Code exact d'un gros fichier à recopier ? Le copier par commande (Copy-Item), pas le lire. **Avant
  chaque lot de lectures, se demander « combien de fichiers ? »** : 3 ou plus = un agent.
- **Interdit de contourner** : si, pour faire passer un test, tu dois ajouter une exception ou un cas spécial, ou si
  deux tests (ou un test et la doc) se contredisent → ne pas coder le contournement. Laisser le test rouge, appeler
  `architecte` (medium, consigne courte : la contradiction exacte, les fichiers) ou me demander de trancher. Jamais
  « douteux à signaler » après coup (Sonnet contourne 3 fois sur 3, Opus refuse).

## État des lieux avant de se lancer

- **Avant chaque tâche, état des lieux de ce qui existe déjà** : code et historique git du projet, outils et
  bibliothèques (GitHub, PyPI…), recherche web (méthodes, normes, exemples). But : **s'en inspirer, ou l'utiliser /
  le copier** plutôt que tout refaire. Vérifier la licence avant de copier du code (et la citer) : me dire si elle
  permet un usage commercial ; absente ou douteuse → ne pas copier, me prévenir. Dire en une ligne ce qui a été trouvé
  et ce qu'on reprend.
- **Proportionné** : petite modif → un coup d'œil au code concerné, sans agent ni recherche web ; nouvelle fonction →
  recherche ciblée (un agent Sonnet au plus) ; gros chantier ou sujet inconnu → vraie recherche (web, GitHub, git).
- **Rappel de Nolann (24/10/2026) : cet état des lieux se perdait.** Toute question ou demande qui crée du NOUVEAU (outil, fonction, méthode, skill, vidéo, mise en page, « est-ce que ça existe ? ») démarre par : 1) `git log`/`grep` du dépôt et des projets voisins ; 2) **`chercheur` (15 recherches mini, GitHub et alternatives)**, lancé en parallèle du reste. **La 1re ligne de ma réponse dit le résultat** : « État des lieux : trouvé X (licence Y), on reprend / rien de probant après N recherches ». Pas de ligne = je l'ai sautée = faute. Seules vraies exceptions : correction d'une ligne, question pure d'explication, suite directe d'un état des lieux déjà fait dans la conversation.

## Applis avec une interface : maquette d'abord, points visuels ensuite

- **Skills et agents** : un skill que seul le fil principal charge ne sert presque jamais, car le travail part chez les agents (sans outil Skill). À chaque skill créé : se demander quel agent doit l'avoir et l'ajouter à sa ligne `skills:` (frontmatter, fichier en LF, jamais CRLF) dans la foulée.
- **Code d'interface (page, CSS, composant, texte visible) → agent `executant-ui`** (skills de design préchargés), jamais `executant`. Le fil principal charge `web-design-guidelines` avant toute retouche d'écran, même petite.
- **Ne pas coder à vue.** Au début d'une appli (ou d'un nouvel écran important) : **architecture + mini maquette**
  avant le code (skills de design, Artifact avec écrans, ou conversation Opus avec captures), validée par moi. Une
  référence (« comme l’appli X ») ne remplace pas la maquette.
  **Barrière (17/10/2026)** : une maquette « belle » se fait en **Opus ultracode**. Sur Sonnet, avant tout travail de
  design : dire « maquette = Opus ultracode », écrire le brief dans `SUIVI.md` et s'arrêter. **Filet** : si une
  maquette a quand même été faite sur Sonnet, le dire en tête du rapport et proposer une passe Opus de retour avant de coder.
  **Première maquette ou changement majeur = Opus ultracode. Changement léger sur une maquette validée = Sonnet puis
  `architecte` relit les captures** ; le rapport donne toujours : captures avant/après côte à côte, liste des
  changements (une ligne chacun), verdict d'`architecte` (2-3 lignes), écarts restants. Sans cela, pas « fait ».
- **Le code doit RESSEMBLER à la maquette validée — règle dure.** Dimensions, espacements, couleurs, textes, ordre,
  états : comme la maquette, pas « dans l'esprit ». **Interdit** de simplifier, remplacer ou laisser tomber un élément
  parce que c'est plus long ou délicat, sans le dire. Une maquette validée est faisable : difficulté technique → **1)
  `architecte` ; 2) poser la question à Nolann** (il préfère changer la maquette que subir un contournement
  silencieux). Tout écart est une **décision à lui**, jamais un choix de Sonnet. Avant « fini » sur un écran :
  **capture côte à côte avec la maquette** et liste des écarts (même vide) dans le rapport / SUIVI.md.
- **Points maquette réguliers** : après un lot de gros changements front + back, ou quand la dernière passe date,
  **me proposer une session Opus ultracode « point maquette »** : lancer la vraie appli, naviguer, prendre des
  captures, vérifier logique et lisibilité, comparer à la maquette et la mettre à jour. Dosage : fin d'un jalon qui
  touche 3 écrans ou plus, ou ajoute un écran ; pas pour une petite correction. L'écrire comme étape dans le plan /
  SUIVI.md d'un chantier d'interface.
- **Avant « fini » sur un écran**, la conversation qui code le lance et le regarde en vrai (Qt :
  `widget.grab().save("x.png")`, même en `offscreen` ; web : navigateur) : lisibilité, alignements, textes coupés,
  états vides et d'erreur. Plus de 2-3 captures → dans un agent. Méthode Qt (captures état par état, contrôle sombre au
  pixel, mesures par introspection) : skill `captures-qt`.
- **Thème sombre de Windows (toutes les applis)** : il casse les interfaces qui se fient aux couleurs du système.
  Toujours fixer soi-même fond **et** texte (Qt : style Fusion + `QPalette` claire explicite + QSS avec `background`
  et `color` sur chaque widget stylé), jamais de couleur « par défaut », et **vérifier chaque nouvel écran, dialogue ou
  popup avec Windows en mode sombre** avant de livrer.

## Produit physique (CAO / SolidWorks)

Concevoir avant de modéliser (schéma 2D coté → prompts d'images → relecture technique → modélisation par étapes) : je le propose moi-même à chaque étape. Workflow complet : `~/.claude/docs/produit_physique_cao.md`.

## Pas de Codex / OpenAI (retiré le 22/10/2026)

- Abonnement OpenAI arrêté, Nolann est passé à Claude Max : **aucun appel à cx.sh / codex**. Tout se fait avec Claude (Sonnet + agents, `architecte` aux déclencheurs, Opus ultracode pour le visuel). Skills codex-gpt, prompts-chatgpt-images laissés installés mais inutilisés (le second sert seulement à écrire des prompts que Nolann colle lui-même dans ChatGPT).
- Échelle d'un bug qui résiste : Sonnet medium (2 essais) → `architecte`.
- Ancienne pipeline Claude + Codex : tag git avec-codex-2026-10-22 (dépôt ~/.claude) et C:\pipeline.

## Skills

- **Nouveau projet ou changement de sujet** : la liste des skills installés est fournie à chaque session ; utiliser ceux
  qui correspondent au travail (ex. écrans Qt : `qt-ui-design` ; textes : `design:ux-copy` ;
  relecture : `design:design-critique`, `design:accessibility-review`).
- Un travail qui se répète ou suit une méthode à nous : **proposer de créer un skill**.
- **Créer/modifier un skill, agent, hook ou règle** : ajouter une ligne (pourquoi, date, mesure) à `docs/registre-config.md`, jamais le pourquoi dans le skill ou ce fichier (coût à chaque message). Le point mensuel relit ce registre ; « mis à jour sur un autre compte » : lancer `outils/inventaire.ps1 -Extra <dossier>`.
