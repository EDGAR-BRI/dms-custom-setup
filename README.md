# 🚀 Edgar's Complete Linux Rice & Setup (CachyOS + Niri + DMS + Howdy)

Repositorio centralizado con **todas mis configuraciones**, temas, widgets, atajos, scripts y módulos de autenticación biométrica para **CachyOS / Arch Linux**.

---

## 📂 Contenido del Repositorio

### 🖥️ 1. Entorno de Escritorio y Compositor
* **Niri** (`.config/niri/`):
  * Configuración completa `config.kdl` con atajos, layouts, bordes y reglas de ventanas.
  * Módulos de integración con DMS (`alttab`, `binds`, `colors`, `cursor`, `input`, `layout`, `outputs`, `windowrules`, `wpblur`).
* **Dux Shell (DMS)** (`.config/dms/`):
  * `settings.json`, `plugin_settings.json`, `plugins.lock.json`, `firefox.css`.
  * **Widgets Personalizados**:
    * `todoList`: Lista de tareas glassmórfica con orden automático y protección en pantalla de bloqueo.
    * `githubStats`: Mapa de calor de contribuciones de GitHub en vivo.
    * `howdySudo`: Interruptor en el Centro de Control para alternar Howdy en `sudo`.

### 🖐️ 2. Gestos de Pantalla Táctil (`local/src/niri-touchd/`)
* Demonio nativo en C (`niri-touchd`) que escucha eventos táctiles del sensor:
  * Deslizar 3 dedos horizontal: Cambiar columna.
  * Deslizar 3 dedos vertical: Cambiar espacio de trabajo.
  * Deslizar 4 dedos vertical: Mover columna al espacio superior/inferior (invertido según preferencia).
  * Pellizco de 4 dedos: Abrir vista general (*Overview*).
  * Deslizar en los bordes: Control de brillo (izq) y volumen (der).
* Servicio de systemd de usuario (`niri-touchd.service`).

### 🔐 3. Autenticación y Desbloqueo Facial Instantáneo (`pam/` y `howdy/`)
* **`pam_check_empty.so`**: Módulo PAM en C que detecta cuando el campo de contraseña está vacío para saltar la validación tradicional e invocar a **Howdy** al instante (0 ms de retraso de hash).
* Reglas PAM para `dankshell` (bloqueo), `sddm` (login) y `sudo`.
* Atajo de Niri (<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>) para alternar Howdy en sudo con notificaciones.
* Perfil de cámara IR optimizado para Dell Latitude 5420 (`howdy/config.ini`).

### 🎨 4. Pantalla de Inicio de Sesión SDDM (`sddm-theme/Corners/`)
* Fondo de Messi con efecto **blur suave (desenfoque frosted)**.
* Reloj digital two-tone blanco y verde neón.
* Píldora de autenticación con avatar circular e icono de candado.
* Widget de estadísticas de GitHub centrado sobre el 10.
* Botón de energía en squircle verde menta pastel y selector de sesión para Niri.

### 💻 5. Terminales, Shells y Apariencia
* **Kitty** (`.config/kitty/`): Configuración de terminal, pestañas (`dank-tabs.conf`) y temas.
* **Fish & Zsh** (`.config/fish/`, `.zshrc`): Funciones, alias (`obsidian-sync`, `hotspot`), integración con fnm y sonido faaa en fallos.
* **Fastfetch** (`.config/fastfetch/`): Perfil visual con logos e imágenes personalizadas.
* **Starship** (`.config/starship/`): Prompt moderno y minimalista.
* **Rofi, Dunst, Btop, Cava, Wlogout**: Configuraciones completas de interfaz y notificaciones.

---

## 🛠️ Cómo Restaurar Todo en una Nueva PC

### 1. Clonar el Repositorio
```bash
git clone https://github.com/EDGAR-BRI/dms-custom-setup.git ~/dms-custom-setup
cd ~/dms-custom-setup
```

### 2. Ejecutar el Instalador
```bash
chmod +x install.sh
./install.sh
```

El script `install.sh` se encargará automáticamente de:
1. Respaldar tus configuraciones actuales en `~/.dotfiles_backup_<fecha>/`.
2. Compilar e instalar el módulo PAM inteligente `pam_check_empty.so`.
3. Instalar las reglas de autenticación en `/etc/pam.d/`.
4. Compilar e iniciar el demonio de gestos `niri-touchd`.
5. Desplegar todos los dotfiles en `~/.config/` y `~/.local/bin/`.
6. Instalar el tema de SDDM en `/usr/share/sddm/themes/Corners`.

---

## 👤 Autor
* **Edgar Briceño** ([@EDGAR-BRI](https://github.com/EDGAR-BRI))
