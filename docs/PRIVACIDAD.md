# Política de privacidad de StudyPlan

**Última actualización:** 27 de noviembre de 2026 (revisión 2)

StudyPlan es un proyecto escolar de TSU en la Universidad Tecnológica del Norte de Guanajuato (UTNG), hecho por Diego Hernández y Kinberly. Aquí explicamos qué datos usa la app, para qué y qué puedes hacer con ellos.

## 1. Qué datos guardamos

| Dato | Para qué |
|---|---|
| Nombre y correo electrónico | Crear tu cuenta, mostrar tu nombre y que un tutor pueda encontrarte por tu correo |
| Rol (estudiante o tutor) | Mostrarte las pantallas que te corresponden |
| Tareas (nombre, descripción, pasos, materia, prioridad y fechas) | Organizar tus entregas y mandarte recordatorios |
| Historial de XP y logros | Calcular tus puntos, tu nivel y tus logros |
| Vínculos con tutores | Que el tutor que aceptaste pueda ver tu avance |

Si entras con **Google**, solo recibimos tu nombre y tu correo. No vemos tu contraseña de Google. Si entras con **correo y contraseña**, Firebase guarda la contraseña cifrada y nosotros nunca la vemos.

## 2. Dónde se guardan

Los datos se guardan en **Google Firebase** (Authentication y Cloud Firestore), en la región `northamerica-south1`. Las reglas de seguridad de la base de datos hacen que:
- solo tú puedas ver y modificar tus tareas;
- un tutor solo pueda **leer** tu avance si tú aceptaste su solicitud, y nunca modificarlo;
- el administrador solo maneje los catálogos de materias y logros, no tus tareas.

## 3. Asistente con IA

Lo que le escribes al asistente se envía a **Gemini** (Google), a través de Firebase AI Logic, para generar la respuesta. Cuando pides ayuda con una tarea, también se envía su nombre y su materia. **StudyPlan no guarda tus conversaciones**: se borran cuando cierras sesión o cierras la app. No escribas datos personales sensibles en el chat.

## 4. Otros servicios

- **Feriados:** la app consulta la API pública Nager.Date para saber los días feriados de México. Solo se pide el año; no se envía ningún dato tuyo.
- **Recordatorios:** se programan en tu propio teléfono (notificaciones locales). No pasan por ningún servidor.

## 5. Lo que NO hacemos

- No vendemos ni compartimos tus datos con nadie.
- No mostramos anuncios.
- No usamos tu ubicación, tus contactos, tu cámara ni tus fotos.

## 6. Tus derechos

- **Ver y corregir** tus datos: desde **Perfil** puedes editar tu nombre y tu correo.
- **Quitar a un tutor:** desde **Perfil → Tutor**.
- **Borrar todo:** desde **Perfil → Eliminar cuenta** se borran tu cuenta, tus tareas, tu XP, tus logros y tus vínculos. No se puede deshacer.
- **Desactivar recordatorios:** desde **Perfil → Ajustes**.

## 7. Menores de edad

La app está pensada para estudiantes. Si eres menor de edad, úsala con el permiso de tu madre, padre o tutor.

## 8. Contacto

Si tienes dudas sobre tus datos, abre un *issue* en el repositorio del proyecto:
<https://github.com/Bkyo13/studdy_plan_proyecto/issues>

Si cambiamos esta política, actualizaremos la fecha de arriba.
