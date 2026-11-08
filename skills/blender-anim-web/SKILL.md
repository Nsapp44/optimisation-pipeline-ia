---
name: blender-anim-web
description: À utiliser pour une animation produit au scroll sur le web (page produit, landing) à partir d'un brouillon 3D Blender à l'échelle. On fait le modèle bpy, puis une séquence d'images et des coordonnées en pixels, puis une animation GSAP ScrollTrigger (canvas + calques HTML/SVG posés par homographie). Méthode du puzzle de mariage (03/11/2026), toujours combinée aux skills de design.
---

# Brouillon Blender → animation web au scroll (méthode validée par l'utilisateur, 03/11/2026)

Idée : un modèle 3D **brouillon mais à l'échelle** donne vite le rendu et cale l'animation au pixel près. l'utilisateur refait un modèle propre plus tard ; le code web, lui, ne change pas, seules les images changent.
Exemple de chaîne : (prep_texture.py → puzzle3d.py → render_seq.py → finish_seq.py) et le mode `puzzle2` de `shoppreview\anim-scroll.js`.

## 0. Design d'abord (règle de l'utilisateur : « faut design avec »)
GSAP tout seul ne suffit pas. Avant d'écrire une ligne :
- Charger les skills de design (`web-design-guidelines`, `design-critique`) ET les skills GSAP (`gsap-core`, `gsap-timeline`, `gsap-scrolltrigger`, `gsap-performance`). Un agent qui n'a pas l'outil Skill reçoit leurs checklists dans son brief.
- Écrire le storyboard en 4-6 temps (ce que l'œil regarde à chaque temps, le texte et sa place, le rythme : où on accélère et où on pose). Une seule idée par temps. La fin = produit posé + phrase + lien vers la personnalisation.
- Respecter la charte de la page : fond, typo, accent, marges. L'objet flotte sur le fond de la page, jamais dans un carré.

## 1. Modèle Blender (agent `architecte`, Opus ; jamais Sonnet pour modéliser)
- Un script bpy **relançable** qui construit toute la scène (`blender -b --python scene.py`), sans clic manuel. Unités en mètres, cotes réelles en constantes en tête du fichier (ex. cadre intérieur 0,80 × 0,60).
- Caméra animée dans le .blend (images 1 → 120), même format que les autres animations (1280 × 853).
- Fond : **transparent (RGBA) + shadow catcher** pour l'ombre au sol ; le fond crème est ajouté ensuite (étape 3). Cycles GPU, 64-128 échantillons : c'est un brouillon.
- **Une seule instance Blender à la fois**, rendus par lots dans un script séquentiel, en arrière-plan (log dans un fichier). Voir la mémoire `feedback-blender-file-attente`.
- Le script **exporte les coordonnées utiles à l'animation** en JSON : coins en pixels (`world_to_camera_view`) des surfaces où viennent se poser les éléments HTML/SVG (ex. `coins_cadre.json` : `photo_plateau`, `ouverture_face_avant`, origine en haut à gauche), pour l'image finale et, si besoin, pour chaque image.

## 2. Séquence
- 40 images environ suffisent pour un zoom caméra (60-90 pour une rotation). Les éléments qui bougent indépendamment (pièces, texte, photo) ne sont PAS dans le rendu : masqués (`hide_render`), ils sont animés en HTML/SVG par-dessus.
- Planche de contrôle (a / b / c : départ, milieu, fin) avant d'aller plus loin : la montrer à l'utilisateur.

## 3. Export web
- PNG RGBA → composé sur la couleur de fond EXACTE de la page → WebP q80, deux tailles **1280 et 640**, `f_000.webp…`, + `poster.webp`, `final.webp`, `manifest.json` (n, tailles, coins).
- Si le fond du WebP ne colle pas pile au fond de la page (compression) : filtre SVG `feComponentTransfer` qui ramène les tons proches au fond, ou `mask-image` en fondu sur les bords.

## 4. Animation GSAP
- Section épinglée (sticky, ~250vh), canvas dessiné en `requestAnimationFrame` **seulement si l'index d'image change** ; préchargement progressif (1 image sur 4 d'abord) ; tier d'images choisi selon la largeur × dpr (max 2), **640 forcé sur téléphone**.
- Une timeline maîtresse `scrub` ; l'index de la séquence et les calques HTML sont pilotés par la même timeline (labels par temps du storyboard).
- Calques posés sur la 3D : homographie 4 coins → `matrix3d` (coins du JSON mis à l'échelle du canvas), recalculée au resize. Contrôle : écart des coins < 0,5 px à 375 / 768 / 1440.
- `transform` et `opacity` seulement ; `will-change` avec parcimonie ; pas de layout dans la boucle.
- `prefers-reduced-motion` ou GSAP absent → `final.webp` fixe + le texte de fin.

## 5. Vérification avant « fait »
- Captures 375 / 768 / 1440 à 0 / 45 / 80 / 100 % du scroll, et reduced-motion ; aucun scroll horizontal ; 0 erreur console.
- Mesures : coins, position du texte de fin dans l'écran, poids total des images chargées sur mobile.
- Relecture des captures par `architecte` (design + mouvement), puis l'utilisateur.

## Pièges connus
- Panneau du navigateur intégré caché = rAF en pause ; émulation mobile peu fiable → captures headless (playwright-core + Chrome) ou iframes de largeur fixe.
- Pieds ou bords coupés dans le cadrage caméra : vérifier le cadrage sur la planche AVANT la séquence.
- Captures headless : vraie copie des images, jamais une jonction.
