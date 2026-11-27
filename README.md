# StudyPlan 📚

App móvil para que los estudiantes organicen sus tareas escolares, reciban recordatorios antes de cada entrega y vean su avance con puntos de experiencia (XP), niveles y logros. Un tutor (por ejemplo, un papá o un asesor) puede dar seguimiento al avance de un estudiante, y un administrador mantiene el catálogo de materias y logros.

Proyecto de TSU · Universidad Tecnológica del Norte de Guanajuato (UTNG).

**Equipo:** Diego Hernández · Kinberly

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

### Estudiante
- **Tareas** con materia, prioridad (alta, media, baja), fecha y hora de entrega.
  - Se completan deslizando la tarjeta a la derecha y se eliminan deslizando a la izquierda, con botón **Deshacer**.
  - Las vencidas salen en su propia sección.
- **Pasos (subtareas):** cada tarea puede dividirse en un checklist con barra de avance.
- **Búsqueda y filtros** por prioridad y materia. La búsqueda ignora acentos y mayúsculas y también revisa los pasos.
- **Calendario** del mes con puntitos por día. Se puede crear una tarea con el día ya puesto, y se avisa si el día es feriado.
- **Recordatorios locales:** 1 día antes y 1 hora antes de cada entrega, configurables desde el perfil.
- **XP:**

  | Concepto | Puntos |
  |---|---|
  | Prioridad alta | 15 |
  | Prioridad media | 10 |
  | Prioridad baja | 5 |
  | Entrega a tiempo | +5 |
  | Entrega tarde | la mitad de los puntos |
  | Completada en menos de 1 hora después de crearla (anti-trampa) | 0 |

- **Niveles:** de Novato a Maestro, con barra hacia el siguiente nivel.
- **Logros:** se desbloquean con el XP y salen con un aviso.
- **Mi progreso:** XP por semana, entregas a tiempo y tareas por materia.
- **Asistente con IA** (Gemini): ayuda a dividir una tarea en pasos y a resolver dudas.
- **Solicitudes de tutor:** el estudiante decide si acepta o rechaza a quien quiere ver su avance, y lo puede quitar después.

### Tutor
- Envía una **solicitud** al correo del estudiante y solo ve sus datos cuando la acepta.
- Ve el resumen del estudiante (pendientes, atrasadas, completadas y XP) y sus tareas, en **solo lectura**.

### Administrador
- Administra el **catálogo de materias** (nombre y color) y el **catálogo de logros** (nombre, descripción y XP requerido).

### Cuenta
- Registro e inicio de sesión con **correo y contraseña** o con **Google**.
- Recuperación de contraseña por correo.
- Edición de perfil y eliminación de la cuenta con todos sus datos.

---

## Tecnologías

| Parte | Herramienta |
|---|---|
| App | Flutter 3.x · Dart 3.7+ |
| Estado | Provider (`ChangeNotifier`) |
| Base de datos | Cloud Firestore (región `northamerica-south1`) |
| Inicio de sesión | Firebase Authentication (correo y Google) |
| IA | Firebase AI Logic · Gemini |
| Seguridad de la API | Firebase App Check |
| Recordatorios | `flutter_local_notifications` + `timezone` |
| Feriados | API pública [Nager.Date](https://date.nager.at) (con caché en `shared_preferences`) |

---

## Estructura del proyecto

```
lib/
├── main.dart              # Firebase, App Check, providers y tema
├── models/                # Usuario, Tarea, Subtarea, Materia, Logro, RegistroXP, Vinculo, Nivel...
├── providers/             # Lógica y conexión con Firestore (auth, tareas, vínculos, logros...)
├── services/              # Notificaciones locales
├── screens/
│   ├── estudiante/        # Inicio, Calendario, Hechas, Logros, Asistente, Detalle, Perfil...
│   ├── tutor/             # Panel del tutor y vincular estudiante
│   └── admin/             # Catálogos de materias y logros
├── theme/                 # Colores, espacios y estilos
├── utils/                 # Animaciones, fechas, validadores, búsqueda...
└── widgets/               # Tarjetas y componentes reutilizables
firestore.rules            # Reglas de seguridad de Firestore
docs/                      # UML, política de privacidad y capturas
```

El diagrama de clases y el modelo de datos están en [docs/UML.md](docs/UML.md).

---

## Datos en Firestore

| Colección | Qué guarda | Quién la modifica |
|---|---|---|
| `usuarios/{uid}` | Nombre, correo, rol y proveedor | El propio usuario |
| `usuarios/{uid}/xp/{tareaId}` | Historial de XP (un registro por tarea) | El estudiante |
| `usuarios/{uid}/logros/{logroId}` | Logros obtenidos | El estudiante |
| `tareas/{id}` | Tareas con sus pasos | Solo su dueño (el tutor vinculado solo las lee) |
| `vinculos/{tutorId}` | Solicitud tutor → estudiante (`pendiente` / `aceptado`) | El tutor la crea; el estudiante la acepta o la borra |
| `materias/{id}` | Catálogo de materias | Administrador |
| `logros/{id}` | Catálogo de logros | Administrador |

Las reglas de [`firestore.rules`](firestore.rules) cumplen esto aunque alguien intente saltarse la app.

---

## Cómo correrlo

Requisitos: Flutter 3.x, Android Studio (SDK de Android) y, para iOS, Xcode.

```bash
git clone https://github.com/Bkyo13/studdy_plan_proyecto.git
cd studdy_plan_proyecto
flutter pub get
flutter run
```

### Generar el APK

```bash
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

> 🔒 La llave de firma (`*.jks`) y `android/key.properties` **no se suben al repositorio**. Sin ellos, el APK sale firmado con la llave de depuración, que sirve para probarlo pero no para distribuirlo.

### Publicar las reglas

Copia el contenido de `firestore.rules` y pégalo en la consola de Firebase, en **Firestore Database → Reglas → Publicar**.

---

## Distribución

Por ahora la app se comparte como **APK** (Android), sin pasar por Google Play ni App Store. Para instalarla hay que permitir "Instalar apps desconocidas" en el teléfono.

---

## Privacidad

Qué datos se guardan y para qué: [docs/PRIVACIDAD.md](docs/PRIVACIDAD.md).
