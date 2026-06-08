# My Access IJL App - Prompts para Google Stitch

Este documento contiene los prompts detallados para generar cada pantalla de la app **My Access IJL** usando **Google Stitch**. Los prompts incluyen descripción visual, colores, componentes, tipografía y comportamientos interactivos.

---

## Identidad Visual General

- **Nombre:** My Access IJL
- **Colores principales:**
  - Primary: `#1B3A6B` (Azul marino)
  - Primary Dark: `#12284D`
  - Accent: `#C9A96E` (Dorado/beige)
  - Background Light: `#F8F9FA`
  - Background Dark: `#0F172A`
  - Surface Light: `#FFFFFF`
  - Surface Dark: `#1E293B`
  - Text Primary: `#1F2937` (light) / `#F1F5F9` (dark)
  - Text Secondary: `#6B7280` (light) / `#94A3B8` (dark)
  - Success: `#10B981`
  - Error: `#EF4444`
- **Tipografía:** Inter o Poppins. Headlines bold, body regular.
- **Radio de bordes:** 12-16dp para botones y cards, 24dp para bottom sheets.
- **Sombras:** Sombra suave en cards (elevation 2-4dp).
- **Logo:** Escudo institucional con libro abierto, águila, serpiente y flechas en azul marino y dorado.

---

## 1. Splash Screen

**Prompt para Stitch:**

```
Create a mobile app splash screen for "My Access IJL", a school attendance tracking app. 

Layout:
- Full screen with background color #1B3A6B (dark navy blue)
- Centered vertically and horizontally: the school logo (an institutional shield with an open book, eagle, snake, and arrows in gold/beige #C9A96E and navy blue)
- Below the logo, the app name "My Access IJL" in white, font Poppins Bold, 28px
- Below the name, a subtle tagline "Seguridad y tranquilidad para tu familia" in #C9A96E, font Poppins Regular, 14px
- At the bottom: a small loading indicator (circular progress) in #C9A96E
- At the very bottom: "v1.0.0" in white with 50% opacity, 12px

Style: Clean, professional, institutional, trustworthy. No clutter. Generous spacing.
```

---

## 2. Login Screen

**Prompt para Stitch:**

```
Create a mobile app login screen for "My Access IJL", a school attendance app for parents and teachers.

Layout:
- Top 40%: Background gradient from #1B3A6B to #12284D. Centered school logo (white/monochrome version) with app name "My Access IJL" in white bold text below it.
- Bottom 60%: White/light background (#F8F9FA). Rounded top corners (24dp radius) creating a card effect.
  - Inside the card:
    - Title: "Bienvenido" in #1F2937, Poppins Bold, 24px
    - Subtitle: "Inicia sesión para recibir notificaciones de acceso" in #6B7280, 14px
    - Spacer 32px
    - A prominent primary button: "Iniciar sesión con Google"
      - Background: white with subtle border
      - Left icon: Google "G" logo (colorful)
      - Text: "Continuar con Google" in #1F2937, font weight 500
      - Height: 56px, border radius: 12px
      - Subtle shadow (elevation 2)
    - Spacer 16px
    - A secondary text link: "¿Necesitas ayuda? Contacta a la escuela" in #1B3A6B, 14px, underlined
    - At the bottom: small text "Al iniciar sesión, aceptas nuestros términos y condiciones" in #6B7280, 12px, centered

Style: Modern, clean, friendly but institutional. The white card overlapping the dark header creates depth. Material Design 3 inspired.
```

---

## 3. Onboarding Screen (Primera vez - Padres)

**Prompt para Stitch:**

```
Create a 3-step onboarding screen for a school parent app called "My Access IJL".

Layout (each step is a full-screen swipeable page):
- Top: A large friendly illustration (flat vector style) showing:
  Step 1: A parent and child at school
  Step 2: A phone scanning a QR code
  Step 3: A phone showing a notification bell with a checkmark
- Middle: Title and description
  Step 1: Title "Bienvenido a My Access IJL" / Desc "La app oficial del Instituto Juárez Lincoln para padres y maestros."
  Step 2: Title "Vincula a tus hijos" / Desc "Escanea el código QR de cada hijo o ingresa su código manualmente para recibir notificaciones."
  Step 3: Title "Recibe notificaciones en tiempo real" / Desc "Te avisaremos cuando tu hijo registre su entrada o salida de la escuela."
- Bottom: Page indicator (3 dots, active dot is #1B3A6B, inactive is #E5E7EB)
  - "Siguiente" button (primary style: #1B3A6B background, white text, 56px height, 12px radius)
  - On step 3, button changes to "Comenzar" with accent color #C9A96E

Colors: Light theme. Primary #1B3A6B, accent #C9A96E. Illustrations use these colors.
Style: Friendly, welcoming, clear. Material Design 3 onboarding pattern.
```

---

## 4. Link Child Screen (Vincular Hijo)

**Prompt para Stitch:**

```
Create a mobile screen for linking a child to a parent account via QR code scanning.

Layout:
- App bar: Back arrow, title "Vincular Hijo", background #1B3A6B, white text
- Body:
  - Top section (60%): Camera preview area with a rounded QR scanning frame in the center.
    - The frame is a square with rounded corners (16dp), border 2px #C9A96E, with corner brackets (L-shapes) at each corner in #C9A96E
    - Overlay outside the frame: semi-transparent dark layer (#1B3A6B at 60% opacity)
    - Label below frame: "Escanea el QR del alumno" in white, 14px
  - Bottom section (40%): White card with rounded top corners (24dp)
    - Tab selector: "Escanear" | "Código manual" (active tab has underline #1B3A6B)
    - If "Código manual" selected: show a text input with label "Código del alumno", placeholder "Ej: ABC123456", and a "Buscar" button (#1B3A6B)
    - Below: A small info card with icon (info circle) and text "El código QR se encuentra en la credencial escolar de tu hijo." in #6B7280

Style: Modern, functional. The camera preview is the hero element. Clean separation between camera and controls. Material Design 3.
```

---

## 5. Home Screen (Padre)

**Prompt para Stitch:**

```
Create a mobile home screen for a parent user in a school attendance app called "My Access IJL".

Layout:
- App bar (not scrolled):
  - Background: #1B3A6B
  - Left: "Hola, [Nombre]" in white, 20px, bold
  - Right: Small circular avatar with user initials on #C9A96E background
- Body (scrollable):
  - Section "Tus hijos vinculados" with title in #1F2937, 18px, bold, and a "+" icon button to add more
  - Vertical list of child cards:
    Each card:
    - White background, rounded 16dp, shadow elevation 2dp, padding 16dp
    - Left: Circular avatar with child initials, background #EEF2FF, text #1B3A6B, 40px diameter
    - Middle:
      - Name: "Juan Pérez García" in #1F2937, 16px, bold
      - Details: "Secundaria - 3°A" in #6B7280, 13px
      - Status chip: "Última entrada: 07:45 AM" with a green dot #10B981, background #ECFDF5, text #065F46, 12px
    - Right: Chevron arrow in #9CA3AF
    - Bottom border of card: subtle divider
  - If no children: Show empty state with illustration of a parent and child, title "Aún no tienes hijos vinculados", subtitle "Toca el botón + para vincular a tu primer hijo", and a CTA button "Vincular hijo" (#1B3A6B)
  - Section "Actividad reciente":
    - Small cards (horizontal scroll or vertical list) showing latest notifications:
      - Icon: door open (entry) or door closed (exit) in #1B3A6B
      - Text: "Juan registró entrada" in #1F2937
      - Time: "Hace 10 min" in #6B7280

Bottom nav: 4 tabs - Home (active, #1B3A6B), QR, Notifications (with red badge "2"), Profile.

Style: Clean, card-based, breathable. Material Design 3. Light theme.
```

---

## 6. Home Screen (Maestro)

**Prompt para Stitch:**

```
Create a mobile home screen for a teacher user in a school attendance app called "My Access IJL".

Layout:
- App bar:
  - Background: #1B3A6B
  - Left: "Hola, Profe [Apellido]" in white, 20px, bold
  - Right: Circular avatar with initials on #C9A96E background
- Body (scrollable):
  - Welcome card (full width):
    - Background gradient: #1B3A6B to #12284D
    - Content: "Tu código de acceso" in white, 16px
    - Large QR code placeholder (white square with QR pattern) centered, 180x180px
    - Subtext: "Muestra este código en el checador" in #C9A96E, 13px
    - Action: "Ampliar QR" text button in white with icon
  - Stats row (2 columns):
    - Card 1: "Entradas esta semana" with number "5" large in #1B3A6B, icon arrow-up
    - Card 2: "Retardos" with number "0" large in #10B981, icon clock
  - Section "Historial de hoy":
    - Timeline items:
      - 07:30 AM - Entrada - green dot #10B981
      - 02:45 PM - Salida - red dot #EF4444
  - Quick action button floating: "Ver mi QR" (small FAB, #C9A96E, icon qr_code)

Bottom nav: 4 tabs - Home (active), QR, Notifications, Profile.

Style: Professional, functional, institutional. Dark hero card with QR. Material Design 3.
```

---

## 7. Child Detail Screen

**Prompt para Stitch:**

```
Create a mobile screen showing detailed attendance history for a specific child.

Layout:
- App bar: Back arrow, title "Juan Pérez García", right action: "Ver QR" icon button, background #1B3A6B
- Header section (sticky or collapsible):
  - Background: #1B3A6B
  - Centered: Large circular avatar with initials "JP", 80px, background #C9A96E, text #1B3A6B, bold
  - Name: "Juan Pérez García" in white, 20px, bold
  - Details: "Secundaria - 3°A" in #C9A96E, 14px
  - Quick stats row (3 mini cards with white background at 10% opacity):
    - "Entradas hoy" → "1"
    - "Salidas hoy" → "0"
    - "Estado" → "En escuela" (green text #10B981)
- Filter tabs (horizontal, below header):
  - "Hoy" | "Semana" | "Mes" (pill-shaped, active: #1B3A6B bg white text, inactive: transparent #1F2937 text)
- Timeline section (scrollable):
  - Vertical timeline with line connecting dots:
    - Entry item: Green dot #10B981, icon door-open, time "07:45 AM", label "Entrada", chip "A tiempo" in green
    - Exit item: Red dot #EF4444, icon door-closed, time "02:30 PM", label "Salida", chip "Normal" in gray
  - Date headers: "Lunes 26 de mayo" in #6B7280, 12px, uppercase
  - If empty: "No hay registros para este período" with calendar icon

Style: Clean timeline, clear visual hierarchy. The sticky header with dark blue creates a nice anchor. Material Design 3.
```

---

## 8. Child QR Screen

**Prompt para Stitch:**

```
Create a full-screen QR code display for a child in a school app.

Layout:
- App bar: Back arrow, title "Código de Juan", background #1B3A6B
- Body (centered vertically and horizontally):
  - Background: #F8F9FA
  - White card (rounded 24dp, padding 32dp, shadow elevation 4dp):
    - Top: "Escanea en el checador" in #1F2937, 16px, bold, centered
    - Center: Large QR code, 250x250px, with padding 16px, border 1px #E5E7EB, rounded 12dp
    - Below QR: "Juan Pérez García" in #1F2937, 18px, bold
    - Below name: "Secundaria - 3°A" in #6B7280, 14px
    - Bottom: Small text "Este código es personal e intransferible" in #EF4444, 12px, with warning icon
  - Below card: "Brillo automático activado" toggle (switch in #1B3A6B, label in #6B7280)

Style: The QR is the hero. Minimal distractions. Card has good shadow to pop. Material Design 3.
```

---

## 9. Teacher QR Screen

**Prompt para Stitch:**

```
Create a full-screen QR code display for a teacher in a school app.

Layout:
- App bar: Back arrow, title "Mi Código de Acceso", background #1B3A6B
- Body:
  - Background: #F8F9FA
  - Large white card centered (rounded 24dp, padding 32dp):
    - Top badge: "MAESTRO" in #C9A96E background (#FEF3C7), text #92400E, 12px, bold, rounded full
    - Spacer 16px
    - "Muestra este código en el checador" in #1F2937, 16px, bold
    - Spacer 24px
    - Large QR code, 280x280px, centered, with padding, border, rounded
    - Spacer 24px
    - Teacher name: "Prof. María González" in #1F2937, 20px, bold
    - Subject/role: "Docente de Matemáticas" in #6B7280, 14px
    - Divider line
    - Small instruction: "Acerca tu teléfono al lector del checador" in #6B7280, 13px, with icon info
  - Bottom floating hint card:
    - Background: #1B3A6B with 5% opacity
    - Text: "Tu código se actualiza automáticamente por seguridad" in #1B3A6B, 12px

Style: Very similar to Child QR but with teacher badge. Professional and authoritative.
```

---

## 10. Notifications Screen

**Prompt para Stitch:**

```
Create a notifications center screen for a mobile school app.

Layout:
- App bar: Title "Notificaciones", right action: "Marcar todo como leído" text button in #C9A96E, background #1B3A6B
- Body (scrollable list):
  - Group by date: "Hoy", "Ayer", "Esta semana" in #6B7280, 12px, bold, uppercase, with left padding
  - Notification items (swipeable to dismiss):
    - Unread: Left border 4px #1B3A6B, background white
    - Read: No border, background #F8F9FA
    - Each item:
      - Left: Circular icon container (48px)
        - Entry: Green background #ECFDF5, icon login/door-open in #10B981
        - Exit: Red background #FEF2F2, icon logout/door-closed in #EF4444
        - System: Blue background #EFF6FF, icon info in #1B3A6B
      - Middle:
        - Title: "Juan Pérez registró su entrada" in #1F2937, 15px, bold (if unread) or regular (if read)
        - Body: "Tu hijo entró a la escuela a las 07:45 AM" in #6B7280, 13px
        - Time: "Hace 10 min" in #9CA3AF, 12px
      - Right: Small unread dot (8px, #1B3A6B) if not read
  - Empty state (if no notifications):
    - Centered illustration of an empty notification bell
    - "No tienes notificaciones" in #1F2937, 18px
    - "Aquí aparecerán las alertas de entrada y salida de tus hijos" in #6B7280, 14px

Bottom nav: Notifications tab active (#1B3A6B), with badge cleared.

Style: Clean list, clear read/unread states. Swipe actions implied. Material Design 3 list pattern.
```

---

## 11. Profile & Settings Screen

**Prompt para Stitch:**

```
Create a profile and settings screen for a school attendance app.

Layout:
- App bar: Title "Perfil", background #1B3A6B, white text
- Body (scrollable):
  - Profile card (full width, background #1B3A6B, padding 24dp):
    - Centered: Large circular photo/avatar (80px) from Google account, or initials fallback on #C9A96E
    - Name: "Carlos Rodríguez" in white, 20px, bold
    - Email: "carlos@email.com" in #C9A96E, 14px
    - Badge: "Padre de familia" or "Maestro" in white background at 15% opacity, rounded full, 12px
  - Settings section (white background, rounded top 24dp, overlaps profile card slightly):
    - Section title "Configuración" in #6B7280, 12px, uppercase, padding 16dp
    - List tiles (each with left icon in #1B3A6B, title in #1F2937, trailing chevron or toggle):
      - [icon notifications] "Notificaciones" → toggle switch (on, #1B3A6B)
      - [icon dark_mode] "Modo oscuro" → toggle switch (off, #1B3A6B) with subtitle "Automático"
      - [icon translate] "Idioma" → "Español" with chevron
      - [icon help] "Ayuda y soporte" → chevron
      - [icon description] "Términos y condiciones" → chevron
      - [icon privacy_tip] "Política de privacidad" → chevron
    - Divider
    - Section "Cuenta":
      - [icon people] "Mis hijos vinculados" → "2" with chevron (only for parents)
      - [icon qr_code] "Mi código QR" → chevron (only for teachers)
    - Divider
    - Danger zone:
      - [icon logout] "Cerrar sesión" in #EF4444, no chevron
  - Footer: "My Access IJL v1.0.0" in #9CA3AF, 12px, centered, padding 24dp

Style: Standard Material Design 3 settings screen. Profile hero with dark blue. Clean list tiles.
```

---

## 12. Notification Detail Bottom Sheet

**Prompt para Stitch:**

```
Create a bottom sheet dialog showing details of a push notification.

Layout (bottom sheet, rounded top corners 24dp):
- Handle bar at top (4px height, 40px width, #E5E7EB, centered)
- Content padding 24dp:
  - Large icon (56px): Entry = green circle #10B981 with door-open icon white. Exit = red circle #EF4444 with door-closed icon white.
  - Title: "Entrada registrada" in #1F2937, 20px, bold, centered
  - Subtitle: "Juan Pérez García" in #1B3A6B, 16px, centered
  - Details card (background #F8F9FA, rounded 12dp, padding 16dp):
    - Row: "Hora" → "07:45 AM" in #1F2937
    - Row: "Fecha" → "Lunes 26 de mayo, 2026" in #1F2937
    - Row: "Tipo" → "Entrada" with green dot
    - Row: "Estado" → "A tiempo" with green badge
  - Action buttons:
    - Primary: "Ver historial completo" (#1B3A6B, white text, full width, 48px height)
    - Secondary: "Cerrar" (transparent, #6B7280 text)

Style: Modern bottom sheet. Clear information hierarchy. Friendly but informative.
```

---

## 13. Loading / Skeleton States

**Prompt para Stitch:**

```
Create skeleton loading states for the home screen of a school attendance app.

Layout:
- App bar skeleton: 24px text placeholder in white on #1B3A6B background
- Body:
  - Section title skeleton: 18px gray bar (#E5E7EB), width 40%, rounded 4px
  - Card skeletons (3 items):
    - Each card: white background, rounded 16dp, padding 16dp
    - Left: circular placeholder 40px, #E5E7EB
    - Middle: 
      - 16px bar (#E5E7EB), width 60%, rounded 4px
      - 13px bar (#E5E7EB), width 40%, rounded 4px, margin top 8px
    - Right: 24px square placeholder, #E5E7EB
  - Shimmer animation overlay: diagonal white gradient (30% opacity) sweeping from left to right repeatedly

Style: Standard skeleton/shimmer pattern. Communicates loading clearly without jank.
```

---

## 14. Error / Empty States

**Prompt para Stitch:

```
Create an empty state illustration for "No hay conexión a internet" in a school app.

Layout (centered):
- Large illustration: A sad/disconnected phone icon in #E5E7EB, 120px
- Title: "Sin conexión" in #1F2937, 20px, bold
- Subtitle: "No pudimos cargar la información. Revisa tu conexión e intenta de nuevo." in #6B7280, 14px, centered, max width 280px
- Action button: "Reintentar" (#1B3A6B background, white text, rounded 12px, 48px height)

Style: Friendly, not alarming. Clear call to action.
```

---

## Instrucciones para Stitch

Para cada pantalla:
1. Copia el prompt correspondiente.
2. Pega en Google Stitch.
3. Selecciona **Mobile App** como formato.
4. Selecciona **Android / Material Design 3** como estilo base.
5. Ajusta colores si es necesario usando los valores hex proporcionados.
6. Exporta en **Figma** o **PNG** según necesites para handoff al desarrollador.

**Nota:** La app tiene dos temas (claro/oscuro). Stitch puede generar variantes. Si no, invierte los colores de fondo y texto para el modo oscuro manteniendo el primary (#1B3A6B) y accent (#C9A96E) iguales.
