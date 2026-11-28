# StudyPlan 📚

**Organiza tus tareas, no se te pasa ninguna entrega y ves tu avance.**

StudyPlan es una app móvil (Android y iPhone) para que los estudiantes registren sus tareas escolares, reciban recordatorios antes de cada entrega y se mantengan motivados con puntos de experiencia (XP), niveles y logros. Incluye un asistente con inteligencia artificial que ayuda a dividir las tareas en pasos. Un tutor (papá, mamá o asesor) puede dar seguimiento al avance del estudiante, siempre que el estudiante lo acepte.

| | |
|---|---|
| **Escuela** | Universidad Tecnológica del Norte de Guanajuato (UTNG) |
| **Carrera** | TSU en Desarrollo de Software Multiplataforma · Grupo GTID-243 |
| **Materia** | Desarrollo de Aplicaciones Móviles |
| **Equipo** | Diego Hernández Bautista · Kinberly Daniela Jaimes|
| **Plataformas** | Android (APK) · iPhone (instalada desde Xcode) |
| **Identificador** | `com.diegohernandez.studyplan` |

---

## Índice

1. [Capturas](#capturas)
2. [Funciones](#funciones)
3. [Sistema de XP, niveles y logros](#sistema-de-xp-niveles-y-logros)
4. [Tecnologías](#tecnologías)
5. [Arquitectura y estructura](#arquitectura-y-estructura)
6. [Datos y seguridad](#datos-y-seguridad)
7. [Instalación y ejecución](#instalación-y-ejecución)
8. [Administración del proyecto](#administración-del-proyecto)
9. [Limitaciones conocidas](#limitaciones-conocidas)
10. [Cómo trabajamos](#cómo-trabajamos)
11. [Privacidad](#privacidad)

---

## Capturas

| Inicio | Detalle con pasos | Calendario | Logros |
|---|---|---|---|
| ![Inicio](docs/capturas/inicio.png) | ![Detalle](docs/capturas/detalle.png) | ![Calendario](docs/capturas/calendario.png) | ![Logros](docs/capturas/logros.png) |

| Asistente IA | Panel del tutor | Admin: materias | Login |
|---|---|---|---|
| ![Asistente](docs/capturas/asistente.png) | ![Tutor](docs/capturas/tutor.png) | ![Admin](docs/capturas/admin.png) | ![Login](docs/capturas/login.png) |

---

## Funciones

La app tiene **3 roles**, y cada uno ve pantallas distintas.

### 🎓 Estudiante

Navega con una barra inferior de 5 pestañas: **Inicio · Calendario · Hechas · Logros · Asistente**.

**Tareas**
- Cada tarea tiene nombre, materia (del catálogo), descripción, fecha y hora de entrega y prioridad (alta, media o baja).
- **Pasos (subtareas):** cada tarea puede dividirse en un checklist de hasta 20 pasos, con barra de avance. Al palomear el último, la app avisa que ya se puede completar.
- **Gestos:** deslizar la tarjeta a la derecha la completa y a la izquierda la elimina. Las dos acciones tienen botón **Deshacer**.
- Las tareas vencidas salen en su propia sección de **Atrasadas**.
- Se puede editar, marcar de nuevo como pendiente o pedir ayuda a la IA desde el detalle de la tarea.

**Encontrar tareas**
- **Buscador** en Inicio y en Hechas. Ignora acentos y mayúsculas ("matematicas" encuentra "Matemáticas") y también busca en la materia, la descripción y los pasos.
- **Filtros** por prioridad y por materia.

**Calendario**
- Vista del mes con un punto en cada día con entregas.
- Botón **+ Agregar** para crear una tarea con el día ya puesto.
- Aviso de **días feriados** de México al elegir una fecha.

**Recordatorios**
- Notificaciones **1 día antes** y **1 hora antes** de cada entrega.
- Se pueden activar o desactivar (todos o cada uno) desde **Perfil → Ajustes**.

**Motivación**
- XP por cada tarea completada, **niveles** de Novato a Maestro y **logros** desbloqueables (ver [la siguiente sección](#sistema-de-xp-niveles-y-logros)).
- **Mi progreso:** XP por semana, porcentaje de entregas a tiempo y tareas por materia.

**Asistente con IA**
- Chat con Gemini que conoce las tareas pendientes del estudiante.
- Sirve para dividir una tarea en pasos, organizar la semana o resolver dudas.
- La conversación no se guarda: se borra al cerrar sesión.

**Tutores**
- Cuando un tutor envía una solicitud, en Inicio aparece el aviso "X quiere ver tu avance", con los botones **Aceptar** y **Rechazar**.
- Desde **Perfil → Tutor** se ve quién tiene acceso y se le puede **quitar** en cualquier momento.

### 👨‍👩‍👧 Tutor
- Envía una **solicitud** escribiendo el correo del estudiante. Mientras no la acepte, ve "Solicitud enviada" y puede cancelarla.
- Cuando el estudiante acepta, ve el resumen de su avance (pendientes, atrasadas, completadas y XP) y la lista de sus tareas con sus pasos.
- Todo es de **solo lectura**: el tutor no puede crear, editar ni completar tareas del estudiante.

### 🛠️ Administrador
- Administra el **catálogo de materias** (nombre y color), que usan todos los estudiantes.
- Administra el **catálogo de logros** (nombre, descripción y XP requerido).
- Este rol **no se elige al registrarse**: se asigna desde la consola de Firebase (ver [Administración](#administración-del-proyecto)).

### 👤 Cuenta (todos los roles)
- Registro e inicio de sesión con **correo y contraseña** o con **Google**.
- **Recuperar contraseña** con un enlace que llega al correo.
- Editar nombre y correo, y cambiar la contraseña.
- **Eliminar la cuenta** con todos sus datos (tareas, XP, logros y vínculos).

### ✨ Detalles de experiencia
- Funciona **sin internet**: Firestore guarda una copia local y sincroniza al volver la conexión.
- Pantallas de carga con **esqueletos** en lugar de pantallas en blanco.
- Animaciones cortas y sobrias (150–220 ms). Si el teléfono tiene activado **"Reducir movimiento"**, se desactivan.
- El teclado se baja al enviar un formulario o al tocar fuera de un campo.
- Paleta verde salvia y blanco, con el mismo estilo en todas las pantallas.

---

## Sistema de XP, niveles y logros

### Puntos por tarea

| Prioridad | XP base |
|---|---|
| Alta | 15 |
| Media | 10 |
| Baja | 5 |

| Situación | Efecto |
|---|---|
| Entregada a tiempo | **+5 XP** de bono |
| Entregada tarde | Se gana **la mitad** del XP base |
| Completada en menos de 1 hora después de crearla | **0 XP** (evita crear y completar tareas solo para subir puntos) |

Cada punto queda en un historial (`usuarios/{uid}/xp`). Si una tarea se marca de nuevo como pendiente, su XP se descuenta.

### Niveles

El nivel se calcula con el XP total. No se guarda en la base de datos: si el XP baja, el nivel también baja.

| Nivel | Nombre | Desde |
|---|---|---|
| 1 | Novato | 0 XP |
| 2 | Aprendiz | 50 XP |
| 3 | Constante | 150 XP |
| 4 | Organizado | 300 XP |
| 5 | Dedicado | 500 XP |
| 6 | Experto | 800 XP |
| 7 | Maestro | 1200 XP |

En Inicio y en Mi progreso se muestra una barra hacia el siguiente nivel, con cuánto falta, por ejemplo "unas 3 tareas". Al subir de nivel, la app lo avisa.

### Logros

El administrador define los logros y el XP que necesita cada uno. Cuando el estudiante llega a ese XP, el logro se desbloquea con un aviso y queda guardado en su perfil.

---

## Tecnologías

| Parte | Herramienta |
|---|---|
| Framework | **Flutter** 3.x · **Dart** 3.7+ · Material 3 |
| Manejo de estado | **Provider** (`ChangeNotifier`) |
| Base de datos | **Cloud Firestore** (región `northamerica-south1`, México) con caché sin conexión |
| Inicio de sesión | **Firebase Authentication** (correo/contraseña y Google) |
| Inteligencia artificial | **Firebase AI Logic** con **Gemini** (`gemini-3.5-flash-lite`) |
| Recordatorios | `flutter_local_notifications` + `timezone` |
| Días feriados | API pública **[Nager.Date](https://date.nager.at)** (con caché en `shared_preferences`) |
| Peticiones HTTP | `http` |
| Plan de Firebase | **Spark** (gratis) |

---

## Arquitectura y estructura

La app separa la interfaz de la lógica: las **pantallas** solo dibujan y llaman a los **providers**. Los providers hablan con Firebase y avisan a las pantallas cuando cambia algo, en tiempo real con los *streams* de Firestore.

```
Pantallas y widgets  →  Providers (ChangeNotifier)  →  Firebase / APIs
```

```
lib/
├── main.dart              # Inicia Firebase y notificaciones, registra providers y tema
├── firebase_options.dart  # Generado por flutterfire (no se edita)
├── models/                # Usuario, Tarea, Subtarea, Materia, Logro, RegistroXP, Vinculo, Nivel, MensajeChat
├── providers/             # Auth, Tarea, Vinculo, Materia, Logro, Asistente, Feriado
├── services/              # Notificaciones locales
├── screens/
│   ├── estudiante/        # Inicio, Calendario, Hechas, Logros, Progreso, Asistente, Detalle, Nueva tarea, Perfil
│   ├── tutor/             # Panel del tutor, tareas del estudiante, vincular
│   └── admin/             # Catálogos de materias y logros
├── theme/                 # Colores, espacios, radios y estilos de texto
├── utils/                 # Animaciones, fechas, validadores, búsqueda, teclado, mensajes
└── widgets/               # Tarjetas y componentes reutilizables
firestore.rules            # Reglas de seguridad de Firestore
docs/                      # UML, política de privacidad, texto del APK y capturas
```

Los diagramas (clases, modelo de datos, capas y flujo de la solicitud de tutor) están en **[docs/UML.md](docs/UML.md)**.

---

## Datos y seguridad

### Colecciones de Firestore

| Ruta | Qué guarda | Quién puede leer / escribir |
|---|---|---|
| `usuarios/{uid}` | Nombre, correo, rol y proveedor (`correo` o `google`) | Lee cualquier usuario con sesión. Cada quien edita solo el suyo y **no puede cambiarse el rol**. |
| `usuarios/{uid}/xp/{tareaId}` | Historial de XP (puntos, motivo, prioridad y fecha) | El estudiante; el tutor aceptado solo lee. |
| `usuarios/{uid}/logros/{logroId}` | Logros obtenidos | El estudiante; el tutor aceptado solo lee. |
| `tareas/{id}` | Tareas con sus pasos (máximo 20) | Solo su dueño; el tutor aceptado solo lee. |
| `vinculos/{tutorId}` | Solicitud tutor → estudiante (`pendiente` o `aceptado`) | El tutor la crea **siempre como pendiente**; solo el estudiante puede aceptarla; ambos pueden borrarla. |
| `materias/{id}` | Catálogo de materias | Leen todos; escribe solo el administrador. |
| `logros/{id}` | Catálogo de logros | Leen todos; escribe solo el administrador. |

### Reglas de seguridad

Las reglas de **[`firestore.rules`](firestore.rules)** se aplican en el servidor, así que se cumplen aunque alguien intente saltarse la app:
- Nadie puede leer ni modificar tareas ajenas.
- Un tutor no ve nada del estudiante hasta que él acepta la solicitud, y nunca puede modificar sus datos.
- Nadie puede ponerse el rol de administrador desde la app.

### Qué no se sube al repositorio
- La llave de firma (`*.jks`) y `android/key.properties`.
- Contraseñas y tokens de depuración.

`firebase_options.dart` y `google-services.json` **sí** se suben: no son secretos, porque la seguridad la dan las reglas de Firestore.

---

## Instalación y ejecución

### Requisitos
- Flutter 3.x
- Android Studio (SDK de Android) para Android
- Mac con Xcode para iPhone

### Correr en desarrollo

```bash
git clone https://github.com/Bkyo13/studdy_plan_proyecto.git
cd studdy_plan_proyecto
flutter pub get
flutter run
```

### Generar el APK (Android)

```bash
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. Para firmarlo con la llave del proyecto hace falta `android/key.properties`; sin él, sale firmado con la llave de depuración, que sirve para probar pero no para distribuir.

**Instalarlo en un teléfono:** se manda el APK (por WhatsApp, Drive, etc.), se abre y se activa **"Instalar apps desconocidas"** cuando lo pida. El texto listo para compartir está en [docs/COMPARTIR_APK.md](docs/COMPARTIR_APK.md).

### Instalar en iPhone

Con el iPhone conectado a la Mac (con **Modo de desarrollador** activado y el desarrollador marcado como de confianza en *Ajustes → General → VPN y gestión de dispositivos*):

```bash
flutter devices                      # copia el id del iPhone
flutter run --release -d <id-del-iphone>
```

> Con una cuenta de Apple gratuita, la app deja de abrir a los **7 días**. Para que vuelva a funcionar, se corre el mismo comando; los datos no se pierden porque están en Firebase.

---

## Administración del proyecto

### Publicar las reglas de Firestore
Copia todo `firestore.rules` y pégalo en la consola de Firebase, en **Firestore Database → Reglas → Publicar**. Hay que hacerlo cada vez que cambia el archivo.

### Crear un administrador
1. Regístrate en la app con una cuenta normal.
2. En la consola de Firebase, ve a **Firestore → usuarios** y abre el documento de esa cuenta.
3. Cambia el campo `rol` a `administrador`.
4. Cierra sesión en la app y vuelve a entrar.

### Inicio de sesión con Google en Android
La huella **SHA-1** de cada computadora que compila la app (y la de la llave de firma) debe estar registrada en la **Configuración del proyecto** de Firebase. Se obtiene con `cd android && ./gradlew signingReport`.

---

## Limitaciones conocidas

- **Sin tiendas de apps:** se distribuye como APK; en iPhone solo se instala desde una Mac con Xcode.
- **Sin notificaciones push:** los recordatorios son locales y se programan en el teléfono.
- **La IA funciona sin App Check:** Firebase App Check está en "No aplicado", porque Play Integrity y App Attest solo funcionan con apps publicadas en las tiendas o con cuenta de Apple de pago. Google empezará a exigirlo para Firebase AI Logic el **21 de enero de 2027**; a partir de esa fecha la IA necesitará tokens registrados por teléfono o publicar la app en una tienda.
- **Límite gratuito de Gemini:** en el plan Spark, si se usa mucho en un día, el asistente deja de responder hasta el día siguiente.
- **Sin inicio de sesión con Apple:** requiere la cuenta de Apple Developer de pago.
- La búsqueda de estudiantes por correo lee la lista de usuarios. Es aceptable para este proyecto, pero se puede mejorar por privacidad.

---

## Cómo trabajamos

- Repositorio en GitHub con **commits chicos**, uno por función, con mensaje en español.
- **Diego:** autenticación (correo y Google), panel de administrador, modelos, tema, logros, splash, publicación (ícono, firma del APK), documentación.
- **Kinberly:** rol estudiante y tutor, tareas y vínculos, XP con historial, pasos, búsqueda, calendario, niveles y solicitudes de tutor.
- Antes de cada cambio: `git pull`; después: `git push` y avisar al otro.

---

## Privacidad

Qué datos se guardan, para qué y cómo borrarlos: **[docs/PRIVACIDAD.md](docs/PRIVACIDAD.md)**.
StudyPlan no vende ni comparte datos y no tiene anuncios.
