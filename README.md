# DMS + SDDM Custom Setup & Instant Facial Unlock 🚀

Configuraciones, temas, complementos y módulo PAM inteligente para **Dux Shell (DMS)**, **SDDM** y autenticación biométrica con **Howdy** en **CachyOS / Arch Linux**.

---

## 🌟 Características Principales

### 1. ⚡ Desbloqueo Facial Instantáneo Inteligente (Howdy)
* **Campo de contraseña vacío**: Al presionar <kbd>Enter</kbd> sin escribir nada, el módulo nativo `pam_check_empty.so` salta la verificación de contraseñas de Unix e invoca a **Howdy** al instante (0 ms de retraso de hash).
* **Contraseña tradicional**: Si escribes tu contraseña y das <kbd>Enter</kbd>, se valida directamente sin encender la cámara ni generar falsos intentos biométricos.
* **Control para Sudo**:
  * Alternador con atajo global <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>.
  * Widget en el Centro de Control de DMS (`howdySudo`).
  * Notificaciones de escritorio en tiempo real del estado de activación.

### 2. 🎨 Pantalla de Inicio de Sesión SDDM Glassmórfica
* Fondo de pantalla con efecto **blur suave (desenfoque frosted)** y capa translúcida para alto contraste.
* **Reloj Two-Tone Gigante**: Horas en blanco sólido (`#ffffff`) y minutos en verde neón (`#3fb950`).
* **Píldora de autenticación**: Avatar circular perfecto, cápsula con borde verde neón y soporte completo para desbloqueo facial instantáneo.
* **Estadísticas de GitHub**: Tarjeta centrada que muestra avatar, usuario, conteo de contribuciones y la matriz (*heatmap*) de commits.
* **Botones integrados**:
  * Botón de energía estilo *squircle* en verde menta pastel (`#9fd5be`) con icono blanco.
  * Selector de sesión con icono de engranaje blanco nítido, priorizando **Niri**.

### 3. 📋 Complementos Personalizados para Dux Shell (DMS)
* **`todoList` (Lista de Tareas)**:
  * Ordenamiento dinámico: Tareas pendientes siempre arriba, completadas se van automáticamente al fondo con tachado y check verde.
  * **Seguridad en Pantalla de Bloqueo**: Oculta botones de eliminación y papelera en la pantalla de bloqueo para evitar borrado accidental o no autorizado.
* **`githubStats` (Estadísticas de GitHub)**:
  * Consulta en vivo vía GraphQL (`gh cli`) o API REST de GitHub.
  * Renderizado interactivo del mapa de contribuciones de los últimos 6 meses.
  * Caché local offline.
* **`howdySudo` (Facial Sudo)**:
  * Interruptor visual en el Centro de Control para activar o desactivar Howdy en `sudo`.

---

## 📦 Estructura del Repositorio

```text
dms-custom-setup/
├── install.sh                  # Script de instalación automática
├── README.md                   # Documentación completa
├── plugins/                    # Complementos para Dux Shell
│   ├── todoList/               # Widget de Tareas
│   ├── githubStats/            # Widget de Estadísticas de GitHub
│   └── howdySudo/              # Widget para alternar Facial Sudo
├── sddm-theme/                 # Tema personalizado para SDDM
│   └── Corners/                # Tema Corners adaptado con blur y widgets
├── pam/                        # Módulo y configuraciones de PAM
│   ├── pam_check_empty.c       # Código fuente C del módulo inteligente
│   ├── dankshell               # Configuración PAM para DMS (Lockscreen)
│   ├── sddm                    # Configuración PAM para SDDM (Login)
│   └── sudo                    # Configuración PAM para Sudo condicional
├── scripts/                    # Scripts auxiliares del sistema
│   ├── toggle-howdy-sudo.sh    # Script ejecutado por el atajo de Niri
│   └── check-howdy-sudo.sh     # Validador para PAM en /etc/pam.d/sudo
└── niri/                       # Atajos de Niri
    └── keybinds-snippet.kdl
```

---

## 🛠️ Instalación en una Nueva PC

### 1. Requisitos Previos
* CachyOS / Arch Linux
* **Howdy** configurado y con tus rostros registrados (`sudo howdy add`)
* **Dux Shell (dms)** y **Niri**
* Compilador GCC y librerías PAM:
  ```bash
  sudo pacman -S --needed base-devel pam gcc jq
  ```

### 2. Clonar e Instalar
```bash
git clone <URL_DEL_REPOSITORIO> ~/dms-custom-setup
cd ~/dms-custom-setup
chmod +x install.sh
./install.sh
```

### 3. Registrar el Atajo en Niri
Añade la siguiente línea en `~/.config/niri/config.kdl` dentro de la sección `binds { ... }`:
```kdl
Mod+Ctrl+Shift+S hotkey-overlay-title="Alternar Reconocimiento Facial Sudo" { spawn-sh "/home/edgar/.local/bin/toggle-howdy-sudo.sh"; }
```
Recarga Niri con:
```bash
niri msg action load-config-file
```

---

## 👤 Autor
* **Edgar Briceño** ([@EDGAR-BRI](https://github.com/EDGAR-BRI))
