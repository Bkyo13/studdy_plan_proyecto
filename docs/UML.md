# StudyPlan · Diagramas

GitHub dibuja estos diagramas automáticamente (Mermaid). Si los abres en otro lado, pega el bloque en <https://mermaid.live>.

## Diagrama de clases (modelos)

```mermaid
classDiagram
    direction LR

    class Rol {
        <<enumeration>>
        estudiante
        tutor
        administrador
    }
    class Prioridad {
        <<enumeration>>
        alta
        media
        baja
    }
    class Estado {
        <<enumeration>>
        pendiente
        completada
    }

    class Usuario {
        +String id
        +String nombre
        +String correo
        +Rol rol
        +String proveedor
        +desdeMapa(id, datos) Usuario
        +aMapa() Map
    }

    class Tarea {
        +String id
        +String nombre
        +String descripcion
        +DateTime fechaEntrega
        +Prioridad prioridad
        +String materiaId
        +String estudianteId
        +Estado estado
        +DateTime? fechaCompletada
        +DateTime? fechaCreacion
        +List~Subtarea~ subtareas
        +bool vencida
        +int subtareasHechas
        +double avanceSubtareas
        +desdeMapa(id, datos) Tarea
        +aMapa() Map
    }

    class Subtarea {
        +String texto
        +bool hecha
        +alternada() Subtarea
    }

    class Materia {
        +String id
        +String nombre
        +String color
    }

    class Logro {
        +String id
        +String nombre
        +String descripcion
        +int xpRequerido
    }

    class EstudianteLogro {
        +String id
        +String estudianteId
        +String logroId
        +DateTime fechaObtenido
    }

    class RegistroXP {
        +String tareaId
        +int puntos
        +String motivo
        +Prioridad prioridad
        +String materiaId
        +String tareaNombre
        +DateTime fecha
    }

    class Vinculo {
        +String tutorId
        +String estudianteId
        +String estado
        +bool esAceptado
        +bool esPendiente
    }

    class Nivel {
        +int numero
        +String nombre
        +int xpMinimo
        +de(xp)$ Nivel
        +Nivel? siguiente
        +avance(xp) double
        +faltan(xp) int
    }

    class MensajeChat {
        +String texto
        +bool deUsuario
        +bool esError
        +DateTime fecha
    }

    Usuario --> Rol
    Tarea --> Prioridad
    Tarea --> Estado
    Tarea "1" *-- "0..20" Subtarea : pasos
    Usuario "1" --> "0..*" Tarea : estudiante
    Tarea "0..*" --> "1" Materia
    Usuario "1" --> "0..*" RegistroXP : historial de XP
    RegistroXP "0..1" --> "1" Tarea : por completar
    Usuario "1" --> "0..*" EstudianteLogro
    EstudianteLogro "0..*" --> "1" Logro
    Vinculo "0..*" --> "1" Usuario : tutor
    Vinculo "0..*" --> "1" Usuario : estudiante
    Nivel ..> RegistroXP : se calcula con la suma de XP
```

Notas:
- Valores posibles: `Usuario.proveedor` es `correo` o `google`; `Materia.color` va en formato `#RRGGBB`; `RegistroXP.motivo` es `a_tiempo`, `tarde` o `muy_rapido`; `Vinculo.estado` es `pendiente` o `aceptado`.
- `Nivel` y `MensajeChat` **no se guardan** en Firestore. El nivel se calcula con el XP total, y la conversación del asistente solo vive mientras la app está abierta.
- Las subtareas se guardan **dentro** del documento de la tarea, en la lista `subtareas`.
- Un tutor tiene como máximo un vínculo, porque el id del documento es el del tutor. Un estudiante puede aceptar a varios tutores.

## Modelo de datos en Firestore

```mermaid
flowchart LR
    U["usuarios/{uid}"]
    XP["usuarios/{uid}/xp/{tareaId}"]
    UL["usuarios/{uid}/logros/{logroId}"]
    T["tareas/{id}"]
    V["vinculos/{tutorId}"]
    M["materias/{id}"]
    L["logros/{id}"]

    U --> XP
    U --> UL
    T -- estudianteId --> U
    T -- materiaId --> M
    UL -- logroId --> L
    V -- tutorId --> U
    V -- estudianteId --> U
```

## Arquitectura (capas)

```mermaid
flowchart TB
    subgraph UI["Pantallas y widgets"]
        E[Estudiante]
        TU[Tutor]
        A[Admin]
    end
    subgraph P["Providers (ChangeNotifier)"]
        AP[AuthProvider]
        TP[TareaProvider]
        VP[VinculoProvider]
        MP[MateriaProvider]
        LP[LogroProvider]
        AsP[AsistenteProvider]
        FP[FeriadoProvider]
    end
    subgraph S["Servicios externos"]
        FA[Firebase Auth]
        FS[Cloud Firestore]
        AI[Gemini · Firebase AI]
        N[Notificaciones locales]
        ND[Nager.Date]
    end

    UI --> P
    AP --> FA
    AP --> FS
    TP --> FS
    TP --> N
    VP --> FS
    MP --> FS
    LP --> FS
    AsP --> AI
    FP --> ND
```

## Flujo: solicitud de tutor

```mermaid
sequenceDiagram
    actor Tutor
    participant App as App del tutor
    participant FS as Firestore
    participant AppE as App del estudiante
    actor Estudiante

    Tutor->>App: Escribe el correo del estudiante
    App->>FS: vinculos/{tutorId} = {estado: pendiente}
    FS-->>AppE: Llega la solicitud (en tiempo real)
    AppE->>Estudiante: "Ana quiere ver tu avance"
    alt Acepta
        Estudiante->>AppE: Aceptar
        AppE->>FS: estado = aceptado
        FS-->>App: El tutor ya puede leer sus tareas y su XP
    else Rechaza
        Estudiante->>AppE: Rechazar
        AppE->>FS: Borra vinculos/{tutorId}
    end
```
