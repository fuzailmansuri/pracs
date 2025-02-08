#!/bin/bash
set -e  # Exit on error

echo "Starting Hyprland setup..."

# Update system
sudo pacman -Syu --noconfirm

# Handle jack2 and pipewire conflicts first
echo "Removing existing audio packages..."
sudo pacman -Rdd jack2 --noconfirm || true
sudo pacman -R pipewire-jack --noconfirm || true

# Install pipewire components separately
echo "Installing audio components..."
sudo pacman -S --noconfirm pipewire
sudo pacman -S --noconfirm pipewire-alsa
sudo pacman -S --noconfirm pipewire-pulse
sudo pacman -S --noconfirm wireplumber
sudo pacman -S --overwrite '*' --noconfirm pipewire-jack

# Install essential packages
sudo pacman -S --noconfirm \
    networkmanager wpa_supplicant wireless_tools iwd dhclient \
    bluez bluez-utils \
    xdg-user-dirs xdg-utils \
    mesa vulkan-intel \
    git curl wget unzip zip tar \
    nano vim neofetch htop \
    sudo

# Enable services
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# Install Hyprland and dependencies
sudo pacman -S --noconfirm \
    hyprland waybar rofi dunst alacritty \
    thunar thunar-volman tumbler gvfs \
    polkit-gnome xdg-desktop-portal-hyprland \
    firefox \
    qt5-wayland qt6-wayland \
    grim slurp \
    pamixer brightnessctl \
    noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd

# Create necessary directories
mkdir -p ~/.config/{hypr,waybar,rofi,dunst,alacritty}

# Download and setup dotfiles
cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Monitor
monitor=,preferred,auto,1.25

# Execute at launch
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = hyprpaper

# Set programs
$terminal = alacritty
$menu = rofi -show drun
$browser = firefox

# Some default env vars
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = GDK_SCALE,1.25
env = QT_SCALE_FACTOR,1.25

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

# General window layout and colors
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee)
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

# Window decorations
decoration {
    rounding = 10
    blur = true
    blur_size = 3
    blur_passes = 1
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
}

# Animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$

# Key bindings
$mainMod = SUPER

bind = $mainMod, Return, exec, $terminal
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, $menu
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, exec, $browser

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10
EOF

# Waybar configuration
cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],
    
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    "network": {
        "format-wifi": "{essid} ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "format-disconnected": "Disconnected ⚠"
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", ""]
        }
    },
    "tray": {
        "icon-size": 21,
        "spacing": 10
    }
}
EOF

# Waybar style
cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(21, 18, 27, 0.9);
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 5px;
    color: #313244;
    border-radius: 0px;
}

#workspaces button.active {
    color: #a6adc8;
    background: #313244;
    border-radius: 0px;
}

#clock,
#battery,
#pulseaudio,
#network,
#workspaces,
#tray {
    background: #1e1e2e;
    padding: 0 10px;
    margin: 3px 0px;
    border-radius: 5px;
}
EOF

# Install SDDM
sudo pacman -S --noconfirm sddm qt5-graphicaleffects qt5-svg
sudo systemctl enable sddm

# Set scaling
echo "Xft.dpi: 120" > ~/.Xresources
echo "export GDK_SCALE=1.25" >> ~/.bashrc
echo "export QT_SCALE_FACTOR=1.25" >> ~/.bashrc

# Create basic alacritty config
cat > ~/.config/alacritty/alacritty.yml << 'EOF'
window:
  padding:
    x: 10
    y: 10
  opacity: 0.95

font:
  normal:
    family: JetBrainsMono Nerd Font
    style: Regular
  size: 11.0

colors:
  primary:
    background: '#1E1E2E'
    foreground: '#CDD6F4'
EOF

# Success message
echo "Setup complete! Please reboot your system."
echo "After reboot, log in through SDDM and Hyprland will start automatically."
echo "Use SUPER + Return for terminal"
echo "Use SUPER + R for application launcher"
echo "Use SUPER + Q to close windows"
echo "Use SUPER + M to exit Hyprland"
