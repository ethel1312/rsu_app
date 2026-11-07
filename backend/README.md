# API del conductor: instalación y despliegue

Backend Node.js independiente de Laravel/XAMPP. El móvil se comunica por HTTPS
con Vercel Functions y la API consulta `rsu_project` en TiDB mediante TLS verificado.
El alcance se mantiene en login, programaciones y detalle del conductor.

## 1. Preparar TiDB y comprobar desde el PC

Abrir PowerShell normal con internet y Node.js 22 o superior:

```powershell
cd D:\ProyectosCODE\rsu_app\backend
npm install
node --env-file=.env scripts/provision.mjs
node --env-file=.env.production scripts/check-db.mjs
npm test
```

El archivo `.env` local ya se preparó desde la configuración existente. Debe
contener las credenciales administrativas de TiDB y apuntar a `rsu_project`, no
`sys`. Si es necesario reconstruirlo, usar `.env.example` como referencia.

`provision.mjs` crea las tablas `mobile_login_attempts` y `mobile_sessions`, y un
usuario de base de datos propio con permisos limitados. No elimina ni reinicializa
las tablas del sistema. Guarda los datos privados de despliegue en `.env.production`.
Si ese archivo ya existe, reutiliza su usuario y secreto y actualiza sus permisos.
No requiere que Laravel esté ejecutándose. `check-db` comprueba TLS y las tablas.
Si falla un paso, resolver ese error antes de continuar.

## 2. Vincular una cuenta Vercel

Crear una cuenta personal en https://vercel.com/signup y ejecutar desde backend:

```powershell
npx --yes vercel@latest login
npx --yes vercel@latest link
```

Vincular esta carpeta a un proyecto nuevo, por ejemplo `rsu-conductor-api`.
Seleccionar carpeta actual (`./`), framework **Other**, sin comando de build ni
carpeta de salida personalizada. No usar la raíz Flutter como raíz de Vercel.
El plan Hobby es gratuito para proyectos personales no comerciales, sujeto a
límites: https://vercel.com/docs/plans/hobby

## 3. Cargar los secretos de producción

```powershell
node scripts/push-env.mjs
```

Este comando lee `.env.production`, valida que no sea un usuario root y carga
cada variable como Secret en el proyecto vinculado de Vercel, entorno Production.
Los valores se envían por entrada estándar; no se imprimen ni se pasan como
argumentos de shell. Requiere la sesión Vercel del paso anterior.

`.env`, `.env.production` y las dependencias locales están excluidos de Git.
`.vercelignore` excluye los archivos privados y los scripts del paquete desplegado.
Las credenciales no se incorporan al APK.

## 4. Permitir las conexiones del backend en TiDB

En TiDB Cloud, abrir el clúster y su **IP Access List** (en Networking/Security,
según la consola). La IP autorizada de tu PC no autoriza la salida de Vercel.

Con salida dinámica en el plan gratuito, se puede permitir `0.0.0.0/0`. Esto
abre el acceso de red a cualquier IP, pero la base sigue exigiendo contraseña y
TLS. Usar el usuario limitado generado, mantener sus datos privados y no quitar
la validación del certificado. No se necesita abrir puertos de tu laptop.

## 5. Publicar y validar

```powershell
npx --yes vercel@latest --prod
```

Usar el dominio estable de producción mostrado en el proyecto (por ejemplo,
`https://rsu-conductor-api.vercel.app`), no una URL temporal de un despliegue.
Abrir su endpoint `/api/health` y comprobar:

```json
{"status":"ok"}
```

Ese endpoint hace una consulta real a TiDB. Si Vercel exige iniciar sesión antes
de mostrar la API, revisar **Settings → Deployment Protection** para que la
producción sea accesible desde el móvil. La autenticación JWT de los endpoints
privados sigue siendo obligatoria.

También comprobar que `GET /api/schedules` sin un JWT devuelva **401**. Si falla
el health, revisar las variables, la IP Access List y los logs de Vercel.

## 6. Crear e instalar el APK

Sustituir el dominio del ejemplo por el dominio estable real:

```powershell
cd D:\ProyectosCODE\rsu_app
C:\src\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=https://rsu-conductor-api.vercel.app/api
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Instalarlo en el
móvil y entrar con el DNI o correo y la contraseña de un empleado activo de tipo
**Conductor**. La asistencia debe estar registrada en el sistema administrativo;
la app solo la consulta. Las programaciones mostradas pertenecen a ese conductor.

Probar con datos móviles y sin Laravel/XAMPP ejecutándose. El móvil necesita
internet; tu laptop puede permanecer apagada.

## JWT y endpoints

Se utiliza la biblioteca `jose` para JWT estándar firmado HS256, algoritmo fijado
en el servidor, emisor `urn:rsu:conductor-api`, destinatario `urn:rsu:conductor-app`,
identificador único, fecha de emisión y vencimiento de 8 horas. Se envía mediante
`Authorization: Bearer ...`. El secreto de firma existe solo en el backend.
No se incluyen contraseñas ni credenciales de TiDB en el JWT.

Cada JWT requiere una sesión vigente en `mobile_sessions`, donde solo se guarda
su hash SHA-256. Cerrar sesión elimina esa sesión del servidor; no basta con
borrar el token del móvil. Cambiar la contraseña o desactivar al conductor también
invalida el acceso. Si no hay conexión, el cierre muestra un error para poder
reintentar la revocación. Al expirar, el conductor debe volver a ingresar.

- `POST /api/login`: DNI/correo y contraseña; solo conductores activos. Convierte
  contraseñas históricas sin hash a bcrypt, como el reloj de asistencia del
  administrador. Límite persistente de 10 intentos por usuario en 15 minutos.
- `POST /api/logout`: revoca el JWT presentado.
- `GET /api/schedules`: perfil y próximas programaciones del conductor;
  respeta días, exclusiones y fecha de Lima.
- `GET /api/schedules/:id?date=YYYY-MM-DD`: detalle y asistencia de su programación.
- `POST /api/schedules/:id/start`: solo hoy y con todas las entradas registradas;
  usa transacción y bloqueo compartido con el administrador para evitar duplicados.
  `recorded_by` es nulo porque referencia usuarios administrativos, no empleados.

## Cambios posteriores

Para actualizar código del backend, desde `backend`:

```powershell
npx --yes vercel@latest --prod
```

Mientras se conserve el dominio estable y la compatibilidad de endpoints y
respuestas, no hay que recompilar ni redistribuir el APK. No volver a crear
usuarios ni rotar el secreto en cada despliegue. Si cambian variables, ejecutar
`node scripts/push-env.mjs` y volver a desplegar. Las pantallas nuevas o cambios
incompatibles en la API sí pueden requerir actualizar el APK.

## Estado de validación en el entorno de edición

No se ha publicado una URL real. La instalación de dependencias está bloqueada
por DNS (`ENOTFOUND registry.npmjs.org`), por lo que la nueva suite JWT requiere
`npm install` y `npm test` en el PC con acceso a internet. La conexión real a TiDB
requiere igualmente ejecutarse desde una red autorizada. No se afirma que el
servicio esté operativo antes de verificar el health y el inicio de sesión.
